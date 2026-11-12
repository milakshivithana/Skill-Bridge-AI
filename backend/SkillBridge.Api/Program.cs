using System;
using System.Text;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using SkillBridge.Api.Data;
using SkillBridge.Api.Services;

var builder = WebApplication.CreateBuilder(args);

// Render.com injects PORT env variable — respect it
var port = Environment.GetEnvironmentVariable("PORT") ?? "8080";
builder.WebHost.UseUrls($"http://0.0.0.0:{port}");

// 1. Add Controllers with JSON ReferenceHandler.IgnoreCycles to prevent EF Core circular reference loops
builder.Services.AddControllers().AddJsonOptions(options =>
{
    options.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
    options.JsonSerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
});

builder.Services.AddHttpClient();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo { Title = "SkillBridge API", Version = "v1" });
    c.AddSecurityDefinition("Bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme. Example: \"Bearer {token}\"",
        Name = "Authorization",
        In = Microsoft.OpenApi.Models.ParameterLocation.Header,
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });
    c.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
    {
        {
            new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference
                {
                    Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

// 2. Configure Database (PostgreSQL with automatic InMemory fallback for local dev/viva)
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

if (string.IsNullOrWhiteSpace(connectionString) || connectionString.Contains("YOUR_DB_PASSWORD"))
{
    connectionString = Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")
        ?? Environment.GetEnvironmentVariable("DATABASE_PUBLIC_URL")
        ?? Environment.GetEnvironmentVariable("DATABASE_URL")
        ?? Environment.GetEnvironmentVariable("DefaultConnection")
        ?? builder.Configuration["DefaultConnection"]
        ?? "";
}

// If PostgreSQL URI format is provided (e.g. postgresql://user:pass@host:port/db), convert to Npgsql connection string
if (!string.IsNullOrWhiteSpace(connectionString) && (connectionString.StartsWith("postgres://") || connectionString.StartsWith("postgresql://")))
{
    try
    {
        var uri = new Uri(connectionString);
        var userInfo = uri.UserInfo.Split(':');
        var user = userInfo[0];
        var pass = userInfo.Length > 1 ? userInfo[1] : "";
        connectionString = $"Host={uri.Host};Port={uri.Port};Database={uri.AbsolutePath.TrimStart('/')};Username={user};Password={pass};SSL Mode=Require;Trust Server Certificate=true;Timeout=30;Command Timeout=30;";
        Console.WriteLine("[DB System] Successfully parsed URI connection string to Npgsql format.");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"[DB Notice] Error parsing URI connection string: {ex.Message}");
    }
}

bool useInMemory = string.IsNullOrWhiteSpace(connectionString) || connectionString.Contains("YOUR_DB_PASSWORD") || connectionString.Contains("PASTE_YOUR_RAILWAY_PASSWORD");

if (!useInMemory)
{
    int retries = 3;
    while (retries > 0)
    {
        try
        {
            using var testConn = new Npgsql.NpgsqlConnection(connectionString);
            testConn.Open();
            useInMemory = false;
            Console.WriteLine("[DB System] Successfully connected to PostgreSQL!");
            break;
        }
        catch (Exception ex)
        {
            retries--;
            if (retries == 0)
            {
                Console.WriteLine($"[DB Notice] PostgreSQL connection failed after retries ({ex.Message}). Using InMemory Database.");
                useInMemory = true;
            }
            else
            {
                Console.WriteLine($"[DB Notice] PostgreSQL is waking up... retrying in 5 seconds ({retries} attempts left)");
                System.Threading.Thread.Sleep(5000);
            }
        }
    }
}

if (useInMemory)
{
    Console.WriteLine("[DB System] Initializing EF Core InMemory Database.");
    builder.Services.AddDbContext<ApplicationDbContext>(options =>
        options.UseInMemoryDatabase("SkillBridgeDb"));
}
else
{
    Console.WriteLine("[DB System] Initializing PostgreSQL Database Provider.");
    builder.Services.AddDbContext<ApplicationDbContext>(options =>
        options.UseNpgsql(connectionString));
}

// 3. Configure JWT Authentication
var jwtSecret = builder.Configuration["JwtSettings:Secret"] ?? "SkillBridge_Super_Secret_Key_For_SE3090_Assignment1_2026_JWT_Tokens!";
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["JwtSettings:Issuer"] ?? "SkillBridge.Api",
        ValidAudience = builder.Configuration["JwtSettings:Audience"] ?? "SkillBridge.Clients",
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret))
    };
});

builder.Services.AddAuthorization();

// 4. Register Application Services
builder.Services.AddScoped<IJwtTokenService, JwtTokenService>();
builder.Services.AddScoped<IDbInitializer, DbInitializer>();
builder.Services.AddSingleton<IProfileCompletenessEvaluator, ProfileCompletenessEvaluator>();
builder.Services.AddScoped<ICandidateService, CandidateService>();

// 5. Configure CORS — dynamically allow any origin (all Vercel preview URLs, production, and localhost)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.SetIsOriginAllowed(_ => true)
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

var app = builder.Build();

// Seed Database & Apply EF Migrations
using (var scope = app.Services.CreateScope())
{
    try
    {
        var dbInitializer = scope.ServiceProvider.GetRequiredService<IDbInitializer>();
        dbInitializer.Initialize();
        Console.WriteLine("[DB System] Database initialized and seeded successfully.");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Database initialization error: {ex.Message}");
    }
}

// Enable Swagger UI
if (app.Environment.IsDevelopment() || app.Environment.IsProduction())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "SkillBridge API v1");
        c.RoutePrefix = "swagger";
    });
}

app.UseCors("AllowAll");

// Global exception handling & CORS preservation middleware
app.Use(async (context, next) =>
{
    try
    {
        await next();
    }
    catch (Exception ex)
    {
        Console.WriteLine($"[CRITICAL EXCEPTION] {context.Request.Method} {context.Request.Path}: {ex.Message}\n{ex.StackTrace}");
        if (!context.Response.HasStarted)
        {
            context.Response.StatusCode = 500;
            context.Response.ContentType = "application/json";
            await context.Response.WriteAsJsonAsync(new
            {
                message = "An internal server error occurred.",
                error = ex.Message,
                detail = app.Environment.IsDevelopment() ? ex.ToString() : null
            });
        }
    }
});

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();

// Expose the entry point for HTTP integration tests using the real authentication pipeline.
public partial class Program { }

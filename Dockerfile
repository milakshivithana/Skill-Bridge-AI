# ── Stage 1: Build ──────────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj and restore
COPY backend/SkillBridge.Api/SkillBridge.Api.csproj backend/SkillBridge.Api/
RUN dotnet restore backend/SkillBridge.Api/SkillBridge.Api.csproj

# Copy everything and build
COPY backend/SkillBridge.Api/ backend/SkillBridge.Api/
WORKDIR /src/backend/SkillBridge.Api
RUN dotnet publish -c Release -o /app/publish

# ── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

COPY --from=build /app/publish .

# Railway injects PORT env variable — ASP.NET Core reads ASPNETCORE_URLS
ENV ASPNETCORE_URLS=http://+:${PORT:-8080}
ENV ASPNETCORE_ENVIRONMENT=Production

EXPOSE 8080

ENTRYPOINT ["dotnet", "SkillBridge.Api.dll"]

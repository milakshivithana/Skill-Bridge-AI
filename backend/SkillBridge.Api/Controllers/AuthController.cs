using System.Linq;
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SkillBridge.Api.Data;
using SkillBridge.Api.DTOs;
using SkillBridge.Api.Models;
using SkillBridge.Api.Services;

namespace SkillBridge.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly ApplicationDbContext _db;
        private readonly IJwtTokenService _jwt;

        public AuthController(ApplicationDbContext db, IJwtTokenService jwt)
        {
            _db = db;
            _jwt = jwt;
        }

        private string HashPassword(string password)
        {
            using var sha256 = SHA256.Create();
            var bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
            return Convert.ToBase64String(bytes);
        }

        [HttpPost("register")]
        public IActionResult Register([FromBody] RegisterDto dto)
        {
            if (_db.Users.Any(u => u.Email.ToLower() == dto.Email.ToLower()))
            {
                return BadRequest(new { message = "User with this email already exists." });
            }

            var user = new User
            {
                FullName = dto.FullName,
                Email = dto.Email,
                PasswordHash = HashPassword(dto.Password),
                Role = dto.Role
            };

            _db.Users.Add(user);
            _db.SaveChanges();

            Candidate? candidate = null;
            Interviewer? interviewer = null;

            if (dto.Role.Equals("Candidate", System.StringComparison.OrdinalIgnoreCase))
            {
                candidate = new Candidate { UserId = user.Id };
                _db.Candidates.Add(candidate);
                _db.SaveChanges();
            }
            else if (dto.Role.Equals("Interviewer", System.StringComparison.OrdinalIgnoreCase))
            {
                interviewer = new Interviewer { UserId = user.Id };
                _db.Interviewers.Add(interviewer);
                _db.SaveChanges();
            }

            var token = _jwt.GenerateToken(user);

            return Ok(new AuthResponseDto
            {
                UserId = user.Id,
                FullName = user.FullName,
                Email = user.Email,
                Role = user.Role,
                CandidateId = candidate?.Id,
                InterviewerId = interviewer?.Id,
                Token = token
            });
        }

        [HttpPost("login")]
        public IActionResult Login([FromBody] LoginDto dto)
        {
            var hashed = HashPassword(dto.Password);
            var user = _db.Users
                .Include(u => u.CandidateProfile)
                .Include(u => u.InterviewerProfile)
                .FirstOrDefault(u => u.Email.ToLower() == dto.Email.ToLower() && u.PasswordHash == hashed);

            if (user == null)
            {
                return Unauthorized(new { message = "Invalid email or password." });
            }

            var token = _jwt.GenerateToken(user);

            return Ok(new AuthResponseDto
            {
                UserId = user.Id,
                FullName = user.FullName,
                Email = user.Email,
                Role = user.Role,
                CandidateId = user.CandidateProfile?.Id,
                InterviewerId = user.InterviewerProfile?.Id,
                Token = token
            });
        }
    }
}

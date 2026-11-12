using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkillBridge.Api.DTOs;
using SkillBridge.Api.Services;

namespace SkillBridge.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class SkillsController : ControllerBase
    {
        private readonly ICandidateService _candidateService;

        public SkillsController(ICandidateService candidateService)
        {
            _candidateService = candidateService;
        }

        /// <summary>
        /// Get all available taxonomy skills.
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetAllSkills()
        {
            var skills = await _candidateService.GetAllTaxonomySkillsAsync();
            return Ok(skills);
        }

        /// <summary>
        /// Add a new taxonomy skill (Candidate, Recruiter, or Admin).
        /// </summary>
        [HttpPost]
        [Authorize(Roles = "Candidate,Recruiter,Administrator")]
        public async Task<IActionResult> CreateSkill([FromBody] CreateSkillDto dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (string.IsNullOrWhiteSpace(dto.Name)) return BadRequest(new { message = "Skill name is required." });

            var created = await _candidateService.CreateTaxonomySkillAsync(dto);
            return Ok(created);
        }
    }
}

using System;
using System.Linq;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SkillBridge.Api.Data;
using SkillBridge.Api.DTOs;
using SkillBridge.Api.Models;

namespace SkillBridge.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CompaniesController : ControllerBase
    {
        private readonly ApplicationDbContext _db;

        public CompaniesController(ApplicationDbContext db)
        {
            _db = db;
        }

        [HttpGet]
        public IActionResult GetCompanies()
        {
            var companies = _db.Companies
                .Include(c => c.Vacancies)
                .Select(c => new CompanyDto
                {
                    Id = c.Id,
                    Name = c.Name,
                    Industry = c.Industry,
                    Location = c.Location,
                    Website = c.Website,
                    ActiveVacanciesCount = c.Vacancies.Count(v => v.IsActive)
                })
                .ToList();

            return Ok(companies);
        }

        [HttpGet("{id}")]
        public IActionResult GetCompany(int id)
        {
            var c = _db.Companies
                .Include(c => c.Vacancies)
                .FirstOrDefault(c => c.Id == id);

            if (c == null) return NotFound(new { message = "Company not found." });

            var dto = new CompanyDto
            {
                Id = c.Id,
                Name = c.Name,
                Industry = c.Industry,
                Location = c.Location,
                Website = c.Website,
                ActiveVacanciesCount = c.Vacancies.Count(v => v.IsActive)
            };

            return Ok(dto);
        }

        [HttpPost]
        public IActionResult CreateCompany([FromBody] CreateCompanyDto dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var company = new Company
            {
                Name = dto.Name,
                Industry = dto.Industry,
                Location = dto.Location,
                Website = dto.Website
            };

            _db.Companies.Add(company);
            _db.SaveChanges();

            return CreatedAtAction(nameof(GetCompany), new { id = company.Id }, new CompanyDto
            {
                Id = company.Id,
                Name = company.Name,
                Industry = company.Industry,
                Location = company.Location,
                Website = company.Website,
                ActiveVacanciesCount = 0
            });
        }
    }
}

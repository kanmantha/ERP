using System.ComponentModel.DataAnnotations;
using System;

namespace ErpApp.Models;

public class Project
{
    [Key]
    public int Id { get; set; }

    [Required]
    [MaxLength(200)]
    public string Title { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public DateTime StartDate { get; set; }
    
    public DateTime? EndDate { get; set; }
}

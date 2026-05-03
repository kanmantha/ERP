using System.ComponentModel.DataAnnotations;

namespace ErpApp.Models;

public class Department
{
    [Key]
    public int Id { get; set; }

    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    public string Location { get; set; } = string.Empty;
}

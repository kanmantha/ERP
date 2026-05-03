using System.ComponentModel.DataAnnotations;

namespace ErpApp.Models;

public class Employee
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    [MaxLength(100)]
    public string FirstName { get; set; } = string.Empty;

    [Required]
    [MaxLength(100)]
    public string LastName { get; set; } = string.Empty;

    public string Position { get; set; } = string.Empty;
}

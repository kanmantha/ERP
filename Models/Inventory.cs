using System.ComponentModel.DataAnnotations;

namespace ErpApp.Models;

public class Inventory
{
    [Key]
    public int Id { get; set; }

    [Required]
    [MaxLength(200)]
    public string ProductName { get; set; } = string.Empty;

    [MaxLength(50)]
    public string SKU { get; set; } = string.Empty;

    public int StockLevel { get; set; }

    public int ReorderPoint { get; set; }

    public string Location { get; set; } = string.Empty;
}

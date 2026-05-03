using System;
using System.ComponentModel.DataAnnotations;

namespace ErpApp.Models;

public class Procurement
{
    [Key]
    public int Id { get; set; }

    [Required]
    [MaxLength(200)]
    public string ItemName { get; set; } = string.Empty;

    public int Quantity { get; set; }

    public decimal UnitPrice { get; set; }

    public DateTime OrderDate { get; set; }

    [MaxLength(100)]
    public string Supplier { get; set; } = string.Empty;

    public string Status { get; set; } = "Pending";
}

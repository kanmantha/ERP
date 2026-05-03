using System;
using System.ComponentModel.DataAnnotations;

namespace ErpApp.Models;

/// <summary>
/// Represents an invoice in the Finance/Accounting module.
/// Used to track billings sent to customers.
/// </summary>
public class Invoice
{
    /// <summary>
    /// The unique identifier for the invoice.
    /// </summary>
    [Key]
    public int Id { get; set; }

    /// <summary>
    /// A human-readable invoice number (e.g. INV-2023-001).
    /// </summary>
    [Required]
    [MaxLength(50)]
    public string InvoiceNumber { get; set; } = string.Empty;

    /// <summary>
    /// The date the invoice was issued.
    /// </summary>
    public DateTime IssueDate { get; set; }

    /// <summary>
    /// The date the payment is due.
    /// </summary>
    public DateTime DueDate { get; set; }

    /// <summary>
    /// The total monetary amount of the invoice.
    /// </summary>
    public decimal TotalAmount { get; set; }

    /// <summary>
    /// The current payment status (e.g., Unpaid, Paid, Overdue).
    /// </summary>
    [MaxLength(20)]
    public string Status { get; set; } = "Unpaid";
}

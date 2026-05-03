using System;
using System.ComponentModel.DataAnnotations;

namespace ErpApp.Models;

/// <summary>
/// Represents a customer in the CRM module of the ERP system.
/// Tracks basic contact and company information for sales purposes.
/// </summary>
public class Customer
{
    /// <summary>
    /// The unique identifier for the customer.
    /// </summary>
    [Key]
    public int Id { get; set; }

    /// <summary>
    /// The name of the customer's company or the individual's full name.
    /// </summary>
    [Required]
    [MaxLength(200)]
    public string CompanyName { get; set; } = string.Empty;

    /// <summary>
    /// The primary contact person for this customer.
    /// </summary>
    [MaxLength(100)]
    public string ContactPerson { get; set; } = string.Empty;

    /// <summary>
    /// The email address used for billing and communication.
    /// </summary>
    [EmailAddress]
    [MaxLength(150)]
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// The primary phone number for the customer.
    /// </summary>
    [Phone]
    [MaxLength(20)]
    public string Phone { get; set; } = string.Empty;
}

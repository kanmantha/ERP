using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using ErpApp.Models;
using ErpApp.Data;

namespace ErpApp.Controllers;

/// <summary>
/// The main controller for handling home page requests.
/// </summary>
public class HomeController : Controller
{
    private readonly ApplicationDbContext _context;

    public HomeController(ApplicationDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Displays the default landing page of the application.
    /// </summary>
    /// <returns>An IActionResult containing the View for the Index page.</returns>
    public IActionResult Index()
    {
        // Seed some data if empty
        if (!_context.Employees.Any())
        {
            _context.Employees.AddRange(
                new Employee { FirstName = "John", LastName = "Doe", Position = "Software Engineer" },
                new Employee { FirstName = "Jane", LastName = "Smith", Position = "Product Manager" },
                new Employee { FirstName = "Alice", LastName = "Johnson", Position = "UX Designer" },
                new Employee { FirstName = "Bob", LastName = "Williams", Position = "HR Specialist" }
            );
            _context.SaveChanges();
        }

        var vm = new DashboardViewModel
        {
            TotalEmployees = _context.Employees.Count(),
            RecentEmployees = _context.Employees.OrderByDescending(e => e.Id).Take(5).ToList()
        };

        return View(vm);
    }

    /// <summary>
    /// Displays the privacy policy page.
    /// </summary>
    /// <returns>An IActionResult containing the View for the Privacy policy.</returns>
    public IActionResult Privacy()
    {
        return View();
    }

    /// <summary>
    /// Displays an error view when an unhandled exception occurs.
    /// </summary>
    /// <returns>An IActionResult containing the Error View model details.</returns>
    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }
}

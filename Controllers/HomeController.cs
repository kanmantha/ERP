using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using ErpApp.Models;

namespace ErpApp.Controllers;

/// <summary>
/// The main controller for handling home page requests.
/// </summary>
public class HomeController : Controller
{
    /// <summary>
    /// Displays the default landing page of the application.
    /// </summary>
    /// <returns>An IActionResult containing the View for the Index page.</returns>
    public IActionResult Index()
    {
        return View();
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

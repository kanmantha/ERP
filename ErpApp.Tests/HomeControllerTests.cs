using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Xunit;
using ErpApp.Controllers;
using ErpApp.Data;

namespace ErpApp.Tests;

public class HomeControllerTests
{
    private ApplicationDbContext GetInMemoryDbContext()
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase(databaseName: System.Guid.NewGuid().ToString())
            .Options;
        return new ApplicationDbContext(options);
    }

    [Fact]
    public void Index_ReturnsAViewResult()
    {
        // Arrange
        using var context = GetInMemoryDbContext();
        var controller = new HomeController(context);

        // Act
        var result = controller.Index();

        // Assert
        Assert.IsType<ViewResult>(result);
    }

    [Fact]
    public void Privacy_ReturnsAViewResult()
    {
        // Arrange
        using var context = GetInMemoryDbContext();
        var controller = new HomeController(context);

        // Act
        var result = controller.Privacy();

        // Assert
        Assert.IsType<ViewResult>(result);
    }
}

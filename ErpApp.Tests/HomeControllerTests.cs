using Microsoft.AspNetCore.Mvc;
using Xunit;
using ErpApp.Controllers;

namespace ErpApp.Tests;

public class HomeControllerTests
{
    [Fact]
    public void Index_ReturnsAViewResult()
    {
        // Arrange
        var controller = new HomeController();

        // Act
        var result = controller.Index();

        // Assert
        Assert.IsType<ViewResult>(result);
    }

    [Fact]
    public void Privacy_ReturnsAViewResult()
    {
        // Arrange
        var controller = new HomeController();

        // Act
        var result = controller.Privacy();

        // Assert
        Assert.IsType<ViewResult>(result);
    }
}

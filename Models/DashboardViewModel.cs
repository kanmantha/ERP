using System.Collections.Generic;

namespace ErpApp.Models;

public class DashboardViewModel
{
    public int TotalEmployees { get; set; }
    public List<Employee> RecentEmployees { get; set; } = new();
}

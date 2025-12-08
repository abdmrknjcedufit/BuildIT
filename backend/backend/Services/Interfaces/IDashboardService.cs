using BuildIT.Model.Models;

namespace BuildIT.Services.Interfaces
{
    public interface IDashboardService
    {
        DashboardStats GetDashboardStats();
        StatisticsData GetStatisticsData();
    }
}


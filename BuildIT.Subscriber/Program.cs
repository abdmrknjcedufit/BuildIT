using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using BuildIT.Subscriber;

var builder = Host.CreateApplicationBuilder(args);

var basePath = Directory.GetCurrentDirectory();
builder.Configuration
    .SetBasePath(basePath)
    .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
    .AddJsonFile("appsettings.Development.json", optional: true, reloadOnChange: true)
    .AddEnvironmentVariables();

builder.Services.AddLogging(configure => configure.AddConsole());
builder.Services.AddHostedService<OrderNotificationWorker>();

var host = builder.Build();

var logger = host.Services.GetRequiredService<ILogger<Program>>();
logger.LogInformation("🚀 BuildIT Subscriber pokrenut");

await host.RunAsync();

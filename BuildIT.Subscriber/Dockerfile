FROM mcr.microsoft.com/dotnet/runtime:8.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["BuildIT.Subscriber/BuildIT.Subscriber.csproj", "BuildIT.Subscriber/"]
COPY ["BuildIT.Model/BuildIT.Model.csproj", "BuildIT.Model/"]
RUN dotnet restore "BuildIT.Subscriber/BuildIT.Subscriber.csproj"
COPY . .
WORKDIR "/src/BuildIT.Subscriber"
RUN dotnet build "BuildIT.Subscriber.csproj" -c Release -o /app/build

FROM build AS publish
WORKDIR "/src/BuildIT.Subscriber"
RUN dotnet publish "BuildIT.Subscriber.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
COPY --from=build /src/BuildIT.Subscriber/appsettings.json .
COPY --from=build /src/BuildIT.Subscriber/appsettings.Development.json .
ENTRYPOINT ["dotnet", "BuildIT.Subscriber.dll"]


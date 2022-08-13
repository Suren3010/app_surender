######################################################
### Creating multi stage image
### Stage 1 - publish code to one folder 'nagp-devops-us-publish'
######################################################
FROM mcr.microsoft.com/dotnet/sdk:3.1 AS publish-code
WORKDIR /nagp-devops-us
COPY nagp-devops-us/nagp-devops-us.csproj ./
RUN dotnet restore
COPY nagp-devops-us ./
RUN dotnet publish -c Release -o nagp-devops-us-publish
### Stage 2 - Creating runtime image from published code
FROM mcr.microsoft.com/dotnet/aspnet:3.1
WORKDIR /nagp-devops-us
COPY --from=publish-code /nagp-devops-us/nagp-devops-us-publish .
ENTRYPOINT ["dotnet", "nagp-devops-us.dll"]
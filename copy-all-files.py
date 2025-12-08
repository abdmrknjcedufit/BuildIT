import os
import shutil
from pathlib import Path

# Base paths
base_path = Path(r"C:\Users\Abdullah\Desktop\BuildIT\BuildIT")
backend_path = base_path / "backend" / "backend"
new_api_path = base_path / "BuildIT.API"
new_model_path = base_path / "BuildIT.Model"
new_services_path = base_path / "BuildIT.Services"
new_subscriber_path = base_path / "BuildIT.Subscriber"
helper_service_path = base_path / "HelperService" / "HelperService"

def copy_directory(src, dst):
    """Copy entire directory recursively"""
    if src.exists() and src.is_dir():
        if dst.exists():
            shutil.rmtree(dst)
        shutil.copytree(src, dst)
        print(f"✅ Copied: {src} -> {dst}")
    else:
        print(f"⚠️ Source not found: {src}")

def copy_file(src, dst):
    """Copy single file"""
    if src.exists() and src.is_file():
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        print(f"✅ Copied: {src.name}")
    else:
        print(f"⚠️ Source not found: {src}")

print("🚀 Starting file copy operations...\n")

# Copy API files
print("📁 Copying API files...")
copy_directory(backend_path / "Controllers", new_api_path / "Controllers")
copy_directory(backend_path / "Filters", new_api_path / "Filters")
copy_directory(backend_path / "Hubs", new_api_path / "Hubs")
copy_directory(backend_path / "Properties", new_api_path / "Properties")
copy_file(backend_path / "Program.cs", new_api_path / "Program.cs")
copy_file(backend_path / "BasicAuthenticationHandler.cs", new_api_path / "BasicAuthenticationHandler.cs")
copy_file(backend_path / "Dockerfile", new_api_path / "Dockerfile")
copy_file(backend_path / "backend.http", new_api_path / "backend.http")
copy_file(backend_path / "appsettings.json", new_api_path / "appsettings.json")
copy_file(backend_path / "appsettings.Development.json", new_api_path / "appsettings.Development.json")

# Copy Model files
print("\n📁 Copying Model files...")
copy_directory(backend_path / "Model" / "Models", new_model_path / "Models")
copy_directory(backend_path / "Model" / "Requests", new_model_path / "Requests")
copy_directory(backend_path / "Model" / "SearchObjects", new_model_path / "SearchObjects")
copy_file(backend_path / "Model" / "PagedResult.cs", new_model_path / "PagedResult.cs")
copy_file(backend_path / "Model" / "UserException.cs", new_model_path / "UserException.cs")

# Copy Services files
print("\n📁 Copying Services files...")
copy_directory(backend_path / "Services" / "Database", new_services_path / "Database")
copy_directory(backend_path / "Services" / "Services", new_services_path / "Services")
copy_directory(backend_path / "Services" / "Interfaces", new_services_path / "Interfaces")
copy_directory(backend_path / "Services" / "Helpers", new_services_path / "Helpers")
if (backend_path / "Migrations").exists():
    copy_directory(backend_path / "Migrations", new_services_path / "Migrations")

# Copy Subscriber files
print("\n📁 Copying Subscriber files...")
if (helper_service_path / "appsettings.json").exists():
    copy_file(helper_service_path / "appsettings.json", new_subscriber_path / "appsettings.json")

print("\n✅ All files copied successfully!")


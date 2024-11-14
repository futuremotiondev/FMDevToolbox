
namespace FMDevToolbox {

    using System;
    using System.Collections;
    using System.Collections.Generic;
    using System.Collections.ObjectModel;
    using System.Management.Automation;

    public class PackageInfo {
        public string Package { get; set; }
        public string Version { get; set; }

        // Constructor
        public PackageInfo (string package, string version) {
            Package = package;
            Version = version;
        }
    }

    public class PythonVenvObject {
        public List<PackageInfo> SitePackagesList = new List<PackageInfo>();
        #nullable enable
        public string? IsVENV { get; set; }
        public string? VENVPath { get; set; }
        public string? PythonVersion { get; set; }
        public string? PythonHome { get; set; }
        public string? ActivateFilePS1 { get; set; }
        public string? ActivateFileBAT { get; set; }
        public string? DeactivateBAT { get; set; }
        public string? SitePackagesDir { get; set; }
        public string? PythonBinary { get; set; }
        public string? PythonDebugBinary { get; set; }
        public string? PIPBinary { get; set; }
        public string? PIPVersion { get; set; }
        public string? IncludeSystemPackages { get; set; }
        public string? ConfigFile { get; set; }
        public Array? ScriptsContent { get; set; }
        #nullable disable
        public PythonVenvObject () { }
        public void AddPackageInfo (string package, string version) {
            SitePackagesList.Add(new PackageInfo(package, version));
        }
    }
}
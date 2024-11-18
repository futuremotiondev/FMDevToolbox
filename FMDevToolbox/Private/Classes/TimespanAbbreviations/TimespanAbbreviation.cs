
namespace FMDevToolbox {

using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Management.Automation;

public static class TimeSpanAbbreviations {
        public static TimeUnit Milliseconds { get; } = new("ms", "ms", "Milliseconds");
        public static TimeUnit Seconds { get; } = new("s", "sec", "Seconds");
        public static TimeUnit Minutes { get; } = new("m", "min", "Minutes");
        public static TimeUnit Hours { get; } = new("h", "hr", "Hours");

        public class TimeUnit {
            public string Short { get; }
            public string Long { get; }
            public string Full { get; }

            public TimeUnit (string shortForm, string longForm, string fullName) {
                Short = shortForm;
                Long = longForm;
                Full = fullName;
            }
        }
    }
}
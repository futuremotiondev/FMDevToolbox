namespace FMDevToolbox.SpectreConsole {

using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Management.Automation;

using Spectre.Console;

public class SpectreConsoleTheme {
        public string? ThemeName { get; set; }
        public string? DefaultAccentColor { get; set; }
        public string? DefaultValueColor { get; set; }
        public string? TableHeaderColor { get; set; }
        public string? TableTextColor { get; set; }
        public string? TableBorderColor { get; set; }
        public string? TableBorderType { get; set; }
        public string? TableTextColorAccent { get; set; }
        public string? ExceptionTypeColor { get; set; }
        public string? ExceptionMessageColor { get; set; }
        public string? ExceptionMessageNonEmphasizedColor { get; set; }
        public string? ExceptionMessageParenthesisColor { get; set; }
        public string? ExceptionMessageMethodColor { get; set; }
        public string? ExceptionMessageParameterNameColor { get; set; }
        public string? ExceptionMessageParameterTypeColor { get; set; }
        public string? ExceptionMessagePathColor { get; set; }
        public string? ExceptionMessageLineNumberColor { get; set; }

        /// <summary>
        /// Initializes a new instance of the FMDevToolbox.SpectreConsole.SpectreConsoleTheme struct /> struct.
        /// </summary>
        /// <param name="red">The red component.</param>
        /// <param name="green">The green component.</param>
        /// <param name="blue">The blue component.</param>
        public SpectreConsoleTheme ()
        {

        }

        /// <summary>
        /// Converts a hex color string (e.g., "#CCCCCC") to a Spectre.Console.Color.
        /// </summary>
        /// <param name="hexColor">The hex color string.</param>
        /// <returns>A Spectre.Console.Color instance.</returns>
        public static Color ConvertHexToSpectreColor(string hexColor)
        {
            if (string.IsNullOrWhiteSpace(hexColor))
            {
                throw new ArgumentException("Color cannot be null or empty.", nameof(hexColor));
            }

            try
            {
                if (hexColor.StartsWith("#"))
                {
                    hexColor = hexColor.TrimStart('#');
                    if (hexColor.Length != 6)
                    {
                        throw new FormatException("Hex color must be 6 characters long.");
                    }

                    byte r = Convert.ToByte(hexColor.Substring(0, 2), 16);
                    byte g = Convert.ToByte(hexColor.Substring(2, 2), 16);
                    byte b = Convert.ToByte(hexColor.Substring(4, 2), 16);

                    return new Color(r, g, b);
                }

                // Assuming valid named color input is handled elsewhere
                return (Color)Enum.Parse(typeof(Color), hexColor, true);
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException("Failed to convert color.", ex);
            }
        }
    }
}

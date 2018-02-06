// --------------------------------------------------------------------------------------------------------------------
// <copyright file="Arguments.cs" company="3MHIS">
//  Copyright 2011 3MHIS
// </copyright>
// <summary>
//   Arguments class used to capture/parse command line parameters to RedGateWrapper.exe.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace RedGateWrapper
{
    using System.Collections.Specialized;
    using System.Text.RegularExpressions;

    /// <summary>
    /// Arguments class which parses command line parameters.
    /// </summary>
    public class Arguments
    {
        // Variables
        #region Constants and Fields

        /// <summary>
        /// The parameters.
        /// </summary>
        private readonly StringDictionary parameters;

        #endregion

        // Constructor
        #region Constructors and Destructors

        /// <summary>
        /// Initializes a new instance of the <see cref="Arguments"/> class.
        /// </summary>
        /// <param name="args">
        /// The args passed from Main.
        /// </param>
        public Arguments(string[] args)
        {
            this.parameters = new StringDictionary();
            var spliter = new Regex(@"^-{1,2}|^/|=|:", RegexOptions.IgnoreCase | RegexOptions.Compiled);

            var remover = new Regex(@"^['""]?(.*?)['""]?$", RegexOptions.IgnoreCase | RegexOptions.Compiled);

            string parameter = null;
            string[] parts;

            // Valid parameters forms:
            // {-,/,--}param{ ,=,:}((",')value(",'))
            // Examples: 
            // -param1 value1 --param2 /param3:"Test-:-work" 
            // /param4=happy -param5 '--=nice=--'
            foreach (string txt in args)
            {
                // Look for new parameters (-,/ or --) and a
                // possible enclosed value (=,:)
                parts = spliter.Split(txt, 3);

                switch (parts.Length)
                {
                        // Found a value (for the last parameter 
                        // found (space separator))
                    case 1:
                        if (parameter != null)
                        {
                            if (!this.parameters.ContainsKey(parameter))
                            {
                                parts[0] = remover.Replace(parts[0], "$1");

                                this.parameters.Add(parameter, parts[0]);
                            }

                            parameter = null;
                        }

                        // else Error: no parameter waiting for a value (skipped)
                        break;

                        // Found just a parameter
                    case 2:

                        // The last parameter is still waiting. 
                        // With no value, set it to true.
                        if (parameter != null)
                        {
                            if (!this.parameters.ContainsKey(parameter))
                            {
                                this.parameters.Add(parameter, "true");
                            }
                        }

                        parameter = parts[1];
                        break;

                        // Parameter with enclosed value
                    case 3:

                        // The last parameter is still waiting. 
                        // With no value, set it to true.
                        if (parameter != null)
                        {
                            if (!this.parameters.ContainsKey(parameter))
                            {
                                this.parameters.Add(parameter, "true");
                            }
                        }

                        parameter = parts[1];

                        // Remove possible enclosing characters (",')
                        if (!this.parameters.ContainsKey(parameter))
                        {
                            parts[2] = remover.Replace(parts[2], "$1");
                            this.parameters.Add(parameter, parts[2]);
                        }

                        parameter = null;
                        break;
                }
            }

            // In case a parameter is still waiting
            if (parameter != null)
            {
                if (!this.parameters.ContainsKey(parameter))
                {
                    this.parameters.Add(parameter, "true");
                }
            }
        }

        #endregion

        // Retrieve a parameter value if it exists 
        // (overriding C# indexer property)
        #region Indexers

        /// <summary>
        /// The this identifier.
        /// </summary>
        /// <param name="param">
        /// The parameter.
        /// </param>
        public string this[string param]
        {
            get
            {
                return this.parameters[param];
            }
        }

        #endregion
    }
}
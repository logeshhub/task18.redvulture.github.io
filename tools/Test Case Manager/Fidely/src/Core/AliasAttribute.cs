﻿/*
 * Copyright 2011 Shou Takenaka
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

using System;

namespace Fidely.Framework
{
    /// <summary>
    /// The attribute that specifies an alias name of a property.
    /// </summary>
    [AttributeUsage(AttributeTargets.Property, AllowMultiple = true, Inherited = false)]
    public sealed class AliasAttribute : Attribute
    {
        /// <summary>
        /// The alias name.
        /// </summary>
        public string Name { get; private set; }

        /// <summary>
        /// The description of alias.
        /// </summary>
        public string Description { get; set; }


        /// <summary>
        /// Initializes a new instance of this class with the specified alias name.
        /// </summary>
        /// <param name="name">The alias name.</param>
        public AliasAttribute(string name)
        {
            Name = name;
        }
    }
}

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

using Fidely.Framework.Compilation.Operators;
using Fidely.Framework;
using System;

namespace Fidely.Framework.Tokens
{
    internal class ComparativeOperatorToken : OperatorToken
    {
        internal ComparativeOperator Operator { get; private set; }


        internal ComparativeOperatorToken(ComparativeOperator op)
            : base(op.Symbol, 1, 0)
        {
            Operator = op;
        }


        public override string ToString()
        {
            return "[cmp:" + Value + "]";
        }
    }
}

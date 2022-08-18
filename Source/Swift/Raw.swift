//
// Raw.swift
// Copyright (C) 2022 Valeriy Savchenko
//
// This file is part of EmacsSwiftModule.
//
// EmacsSwiftModule is free software: you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version.
//
// EmacsSwiftModule is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
// or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
// more details.
//
// You should have received a copy of the GNU General Public License along with
// EmacsSwiftModule. If not, see <https://www.gnu.org/licenses/>.
//
import EmacsModule

/// A raw C pointer type from Emacs for the runtime.
public typealias RuntimePointer = UnsafeMutablePointer<emacs_runtime>

typealias RawEmacsValue = emacs_value?
typealias RawEnvironment = UnsafeMutablePointer<emacs_env>?
typealias RawOpaquePointer = UnsafeMutableRawPointer
typealias RawValuePointer = UnsafeMutablePointer<RawEmacsValue>?
typealias RawFunctionType = @convention(c) (
  RawEnvironment, Int, RawValuePointer, UnsafeMutableRawPointer?
) -> RawEmacsValue
typealias RawFinalizer = @convention(c) (RawOpaquePointer?) -> Void

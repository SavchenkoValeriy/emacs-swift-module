add_library(EmacsSwiftModule SHARED
  Init.swift
)
set_target_properties(EmacsSwiftModule PROPERTIES
  Swift_LANGUAGE_VERSION 5)
set_target_properties(EmacsSwiftModule PROPERTIES
  COMPILE_FLAGS "-import-objc-header ${CMAKE_CURRENT_SOURCE_DIR}/EmacsSwiftModule-Bridging-Header.h")

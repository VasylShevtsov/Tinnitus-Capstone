//
//  Supabase.swift
//  Tinnitus Capstone
//
//  Created by Basil Shevtsov on 11/3/25.
//

import Foundation
import Supabase

let supabase = SupabaseClient(
  supabaseURL: URL(string: "https://kxskqyohcebixhjgzadp.supabase.co")!,
  supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt4c2txeW9oY2ViaXhoamd6YWRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIyMDIyNjIsImV4cCI6MjA3Nzc3ODI2Mn0.QuAG8_ebHWVEuXzXDhUcH7xZbj5Y0Kp9oC0F-athaQM"
)

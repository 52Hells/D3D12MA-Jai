AT_COMPILE_TIME :: true;

D3D12MA_PATH :: "src/D3D12MemoryAllocator-3.2.0";

DECLARATIONS_TO_OMIT :: string.[
    "D3D12MA_IMPORTS",
    "_ALLOW_COMPILER_AND_STL_VERSION_MISMATCH",
];

#if AT_COMPILE_TIME {
    #run,stallable {
        set_build_options_dc(.{do_output=false});
        root_options := get_build_options();
        args := root_options.compile_time_command_line;
        if !generate_bindings(args) {
            compiler_set_workspace_status(.FAILED);
        }
    }
} else {
    #import "System";

    main :: () {
        set_working_directory(path_strip_filename(get_path_of_running_executable()));
        args := get_command_line_arguments();
        if !generate_bindings(args) {
            exit(1);
        }
    }
}

generate_bindings :: (args: [] string) -> bool {
    compile        := array_find(args, "-compile");
    compile_debug  := array_find(args, "-debug");

    agility_include_path := tprint("%../d3d12/agility_sdk/include", #filepath);

    if compile {
        src_files: [..] string;
        array_add(*src_files, tprint("%/src/D3D12MemAlloc.cpp", D3D12MA_PATH));

        extra: [..] string;
        array_add(*extra, "/DD3D12MA_EXPORTS", "/std:c++17", "/EHsc");
        if !compile_debug  array_add(*extra, "/DNDEBUG");
        array_add(*extra, tprint("/I%", agility_include_path));
        array_add(*extra, tprint("/I%/include", D3D12MA_PATH));

        success := true;
        #if OS == .WINDOWS {
            make_directory_if_it_does_not_exist("windows");
            success &&= build_cpp_dynamic_lib("windows/D3D12MA", ..src_files, extra = extra, debug=compile_debug);
        } else {
            assert(false);
        }

        if !success     return false;
    }

    output_filename: string;
    opts: Generate_Bindings_Options;
    {
        using opts;

        #if OS == .WINDOWS {
            array_add(*libpaths, "windows");
            output_filename = "windows.jai";
        } else {
            assert(false);
        }

        array_add(*libnames,      "D3D12MA");
        array_add(*system_include_paths, agility_include_path);
        array_add(*system_include_paths, ..get_default_system_include_paths());
        array_add(*include_paths, tprint("%/include", D3D12MA_PATH));
        array_add(*source_files,  tprint("%/include/D3D12MemAlloc.h", D3D12MA_PATH));
        array_add(*extra_clang_arguments, "-x", "c++", "-DWIN32_LEAN_AND_MEAN", "-DD3D12MA_IMPORTS", "-D_ALLOW_COMPILER_AND_STL_VERSION_MISMATCH");
        log_stripped_declarations = false;
        generate_compile_time_struct_checks = false;

        visitor = d3d12ma_visitor;
    }

    return generate_bindings(opts, output_filename);
}

d3d12ma_visitor :: (decl: *Declaration, parent_decl: *Declaration) -> Declaration_Visit_Result {
    if !parent_decl && array_find(DECLARATIONS_TO_OMIT, decl.name) {
        decl.decl_flags |= .OMIT_FROM_OUTPUT;
        return .STOP;
    }

    if decl.kind == .ENUM && ends_with(decl.name, "_FLAGS") {
        en := cast(*Enum)decl;
        en.flags |= .IS_ENUM_FLAGS;
        en.flags |= .VALUES_IN_HEX;

        if en.type && en.type.size == 4 {
            en.type = context.generator.type_def_u32;
        }
    }

    if parent_decl && parent_decl.name == "IUnknownImpl" && decl.kind == .DECLARATION && decl.name == "m_RefCount" {
        decl.type = context.generator.type_def_u32;
    }

    return .RECURSE;
}

#import "Basic";
#import "Bindings_Generator";
#import "BuildCpp";
#import "Compiler";
#import "File";
#import "String";

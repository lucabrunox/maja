/* valacompiler.vala
 *
 * Copyright (C) 2006-2010  Jürg Billeter
 * Copyright (C) 1996-2002, 2004, 2005, 2006 Free Software Foundation, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Jürg Billeter <j@bitron.ch>
 */

using GLib;
using Vala;

class Maja.Compiler {
	static string basedir;
	static string directory;
	[CCode (array_length = false, array_null_terminated = true)]
	static string[] sources;
	[CCode (array_length = false, array_null_terminated = true)]
	static string[] vapi_directories;
	static string vapi_filename;
	static string library;
	[CCode (array_length = false, array_null_terminated = true)]
	static string[] packages;
	[CCode (array_length = false, array_null_terminated = true)]
	static string[] fast_vapis;

	static string fast_vapi_filename;
	static string symbols_filename;
	static string output;
	static bool debug;
	static bool mem_profiler;
	static bool disable_assert;
	static bool enable_checking;
	static bool deprecated;
	static bool experimental;
	static bool disable_warnings;
	static string dump_tree;
	[CCode (array_length = false, array_null_terminated = true)]
	static string[] defines;
	static bool quiet_mode;
	static bool verbose_mode;
	static bool nostdpkg;
	static bool fatal_warnings;
	static string dependencies;

	static string entry_point;

	static bool run_output;

	private CodeContext context;

	const OptionEntry[] options = {
		{ "vapidir", 0, 0, OptionArg.FILENAME_ARRAY, ref vapi_directories, "Look for package bindings in DIRECTORY", "DIRECTORY..." },
		{ "pkg", 0, 0, OptionArg.STRING_ARRAY, ref packages, "Include binding for PACKAGE", "PACKAGE..." },
		{ "vapi", 0, 0, OptionArg.FILENAME, ref vapi_filename, "Output VAPI file name", "FILE" },
		{ "library", 0, 0, OptionArg.STRING, ref library, "Library name", "NAME" },
		{ "basedir", 'b', 0, OptionArg.FILENAME, ref basedir, "Base source directory", "DIRECTORY" },
		{ "directory", 'd', 0, OptionArg.FILENAME, ref directory, "Output directory", "DIRECTORY" },
		{ "fast-vapi", 0, 0, OptionArg.STRING, ref fast_vapi_filename, "Output vapi without performing symbol resolution", null },
		{ "use-fast-vapi", 0, 0, OptionArg.STRING_ARRAY, ref fast_vapis, "Use --fast-vapi output during this compile", null },
		{ "deps", 0, 0, OptionArg.STRING, ref dependencies, "Write make-style dependency information to this file", null },
		{ "symbols", 0, 0, OptionArg.FILENAME, ref symbols_filename, "Output symbols file", "FILE" },
		{ "output", 'o', 0, OptionArg.FILENAME, ref output, "Place output in file FILE", "FILE" },
		{ "debug", 'g', 0, OptionArg.NONE, ref debug, "Produce debug information", null },
		{ "enable-mem-profiler", 0, 0, OptionArg.NONE, ref mem_profiler, "Enable GLib memory profiler", null },
		{ "define", 'D', 0, OptionArg.STRING_ARRAY, ref defines, "Define SYMBOL", "SYMBOL..." },
		{ "main", 0, 0, OptionArg.STRING, ref entry_point, "Use SYMBOL as entry point", "SYMBOL..." },
		{ "nostdpkg", 0, 0, OptionArg.NONE, ref nostdpkg, "Do not include standard packages", null },
		{ "disable-assert", 0, 0, OptionArg.NONE, ref disable_assert, "Disable assertions", null },
		{ "enable-checking", 0, 0, OptionArg.NONE, ref enable_checking, "Enable additional run-time checks", null },
		{ "enable-deprecated", 0, 0, OptionArg.NONE, ref deprecated, "Enable deprecated features", null },
		{ "enable-experimental", 0, 0, OptionArg.NONE, ref experimental, "Enable experimental features", null },
		{ "disable-warnings", 0, 0, OptionArg.NONE, ref disable_warnings, "Disable warnings", null },
		{ "fatal-warnings", 0, 0, OptionArg.NONE, ref fatal_warnings, "Treat warnings as fatal", null },
		{ "quiet", 'q', 0, OptionArg.NONE, ref quiet_mode, "Do not print messages to the console", null },
		{ "verbose", 'v', 0, OptionArg.NONE, ref verbose_mode, "Print additional messages to the console", null },
		{ "", 0, 0, OptionArg.FILENAME_ARRAY, ref sources, null, "FILE..." },
		{ null }
	};
	
	private int quit () {
		if (context.report.get_errors () == 0 && context.report.get_warnings () == 0) {
			return 0;
		}
		if (context.report.get_errors () == 0 && (!fatal_warnings || context.report.get_warnings () == 0)) {
			if (!quiet_mode) {
				stdout.printf ("Compilation succeeded - %d warning(s)\n", context.report.get_warnings ());
			}
			return 0;
		} else {
			if (!quiet_mode) {
				stdout.printf ("Compilation failed: %d error(s), %d warning(s)\n", context.report.get_errors (), context.report.get_warnings ());
			}
			return 1;
		}
	}

	private int run () {
		context = new CodeContext ();
		CodeContext.push (context);

		// default to build executable
		if (output == null) {
			// strip extension if there is one
			// else we use the default output file of the C compiler
			if (sources[0].rchr (-1, '.') != null) {
				long dot = sources[0].pointer_to_offset (sources[0].rchr (-1, '.'));
				output = Path.get_basename (sources[0].substring (0, dot));
			}
		}

		context.assert = !disable_assert;
		context.checking = enable_checking;
		context.deprecated = deprecated;
		context.report.enable_warnings = !disable_warnings;
		context.report.set_verbose_errors (!quiet_mode);
		context.verbose_mode = verbose_mode;

		context.output = output;
		if (basedir == null) {
			context.basedir = CodeContext.realpath (".");
		} else {
			context.basedir = CodeContext.realpath (basedir);
		}
		if (directory != null) {
			context.directory = CodeContext.realpath (directory);
		} else {
			context.directory = context.basedir;
		}
		context.vapi_directories = vapi_directories;
		context.debug = debug;
		context.mem_profiler = mem_profiler;
		nostdpkg |= fast_vapi_filename != null;
		context.nostdpkg = nostdpkg;

		context.entry_point_name = entry_point;

		context.run_output = run_output;

		if (defines != null) {
			foreach (string define in defines) {
				context.add_define (define);
			}
		}

        context.profile = Vala.Profile.DOVA;

        if (!nostdpkg) {
			context.add_external_package ("js-lang");
			context.add_external_package ("dova-base-0.1");
		}

		if (fast_vapis != null) {
			foreach (string vapi in fast_vapis) {
				var rpath = CodeContext.realpath (vapi);
				var source_file = new SourceFile (context, SourceFileType.FAST, rpath);
				context.add_source_file (source_file);
			}
		}
		
		if (context.report.get_errors () > 0 || (fatal_warnings && context.report.get_warnings () > 0)) {
			return quit ();
		}

        context.codegen = new JSCodeGenerator ();

		foreach (string source in sources) {
          context.add_source_filename (source, false);
		}

		sources = null;
		
		var parser = new Parser ();
		parser.parse (context);

		if (context.report.get_errors () > 0 || (fatal_warnings && context.report.get_warnings () > 0)) {
			return quit ();
		}

		if (fast_vapi_filename != null) {
			var interface_writer = new CodeWriter (CodeWriterType.FAST);
			interface_writer.write_file (context, fast_vapi_filename);
			return quit ();
		}
		
		var resolver = new SymbolResolver ();
		resolver.resolve (context);
		
		if (context.report.get_errors () > 0 || (fatal_warnings && context.report.get_warnings () > 0)) {
			return quit ();
		}

		context.check ();

		if (context.report.get_errors () > 0 || (fatal_warnings && context.report.get_warnings () > 0)) {
			return quit ();
		}

		context.codegen.emit (context);

		if (context.report.get_errors () > 0 || (fatal_warnings && context.report.get_warnings () > 0)) {
			return quit ();
		}

		if (vapi_filename == null && library != null) {
			// keep backward compatibility with --library option
			vapi_filename = "%s.vapi".printf (library);
		}

		return quit ();
	}

	static int main (string[] args) {
		// initialize locale
		Intl.setlocale (LocaleCategory.ALL, "");

		try {
			var opt_context = new OptionContext ("- Maja Compiler");
			opt_context.set_help_enabled (true);
			opt_context.add_main_entries (options, null);
			opt_context.parse (ref args);
		} catch (OptionError e) {
			stdout.printf ("%s\n", e.message);
			stdout.printf ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
			return 1;
		}
				
		if (sources == null && fast_vapis == null) {
			stderr.printf ("No source file specified.\n");
			return 1;
		}
		
		var compiler = new Compiler ();
		return compiler.run ();
	}
}

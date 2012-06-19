Furnace-AVM2
============

Furnace-AVM2 is a library for manipulating Adobe Flash ActionScript 3 bytecode. The library contains routines for reading and writing the bytecode in native Flash binary format and transformations between various flavors of abstract syntax trees suited for automatic and manual analysis.

This library can solve wide range of tasks, including but not limited to:

 * **Deobfuscation.** Currently, only an opcode-level dead code eliminator is provided, which is nevertheless proved itself quite useful. A name normalization routine which transforms the names in the source code back to a human-readable form is also provided.
 * **Decompilation.** One of the provided AST transformations emits back the source code in ActionScript 3. One of the development goals was to produce code which can be compiled back and perform the identical actions. It was (mostly) achieved.
 * **Behavioral matching of code.** Furnace matchers provide a powerful [regular language](http://en.wikipedia.org/wiki/Regular_languages) and can be used to locate statement level or control flow level constructs. For example, a matcher could:

    * Find all statement sequences of the form

            var <var>:String = Loader.loadURL(<url>);
            trace(<var>);

      where `<x>` correspond to wildcards which capture and remember values.

    * Find all loops of the form

            for(var <var>:<type> in [object.getParent().getList()|object.getList()]) {
              ...
            	var descendant:<type> = <var>.getDescendant();
            	...
            }

      where `<x>` correspond to wildcards as described above and `[y|x]` means that either of variants `y` or `x` is accepted in place of the construct.

 * **Patching.** The library does not allow transformation of abstract syntax trees back to bytecode, but it retails a lot of information about origin of constructs and allows to modify every other aspect of the bitstream.

The library supports all known AVM2 opcodes, including undocumented (generic types) and Alchemy ones. Most of these opcodes are supported down to source level, with a notable exception of some [E4X](http://en.wikipedia.org/wiki/E4X), which are just too braindead to implement.

The library is extensible. A new transformation can easily be plugged in, shall such a need to arise. Adding support for a certain obfuscator boils down to adding one or two stages to the pipeline, which would normalize the mangled code.

The library is portable and fast. It works on 1.9 rubies: MRI, JRuby and (if you're lucky) Rubinius. It can decompile circa 9000 methods per 30s (on JRuby 1.7 and 8-core Intel i7).

Installation
------------

Furnace-AVM2 is written in Ruby 1.9. You will need to install a compatible Ruby implementation. JRuby is recommended as supports real multithreading mode, but Ruby MRI is also acceptable.

Install the required gems:

    $ gem install furnace-avm2 furnace-swf

Command line interface
----------------------

Furnace-AVM2 has two main command-line utilites, `furnace-avm2` and `furnace-avm2-decompiler`. There is also a supplementary utility called `furnace-swf` which is contained in the gem with the same name.

Note that this library only operates with raw bytecode. It does not know anything about SWF files nor can it parse them.

To analyze a real-world file, which most certainly will be an SWF, you will need to use `furnace-swf` first. It can parse the whole SWF file (including compressed ones), but only supports DoABC2 tags which contain AVM2 bytecode.

The `furnace-swf` utility currently has three subcommands, `abclist`, `abcextract` and `abcreplace`. They should be mostly self-explanatory; an example session is shown below.

    $ furnace-swf -i sample.swf abclist
    ABC tags:
      "frame1": 1488672 byte(s)
    $ furnace-swf -i sample.swf abcextract -n frame1 -o frame1.abc
    $

After you have extracted the AVM2 bytecode, you can use Furnace-AVM2 itself. First, if you think that the file might be obfuscated, you need to preprocess it to clean the obfuscation artifacts. Run the `furnace-avm2` utility in DCE mode (the names are normalized by default; if you don't need that, pass `-q`).

    $ furnace-avm2 -i frame1.abc -d -o frame1.abc
    $

`furnace-avm2` generally works on the method level. It builds a set of methods to work on (`-O` and `-E` options), and then performs various transformations on them. If you need to determine why a particular method fails or to retrieve AST in free-text form, it's a right utility to use. Check its inline help and don't hesitate to experiment with different options.

Contrary to that, `furnace-avm2-decompiler` works on a class level. You can include and exclude objects to decompile with the class granularity, and it doesn't have much more configuration than that.

    $ furnace-avm2-decompiler -i frame1.abc -d -D funids >frame1.as
    Reading input data...
    Found 2434 classes and packages.
    Decompiling... 2402/2434 /
               Decompiled: 9167/9201 (99%)
     Partially decompiled: 8/9201 (0%)
                   Failed: 26/9201 (0%)
    Time taken: 69.27s
    $

The `-D funids` option adds a comment with method body index for each decompiled method. It can be used for debugging decompiler failures.

You'll notice that some methods probably will not get decompiled. (The file I used in this example is quite complex.) Not every possible bytecode sequence can be directly represented in ActionScript 3, and there are some corner cases yet to be described in the decompiler. For "partially decompiled" (i.e. where there were no control flow uncertainites, but some expressions were impossible to transform to ActionScript) the relevant NF-AST code is automatically emitted. You can look at it manually with `furnace-avm2 -n`. For "failed" methods there is no generated code, but you might try to look at control flow graph (`furnace-avm2 -C`, look for emitted `method-*.dot` file) in [Graphviz](http://en.wikipedia.org/wiki/Graphviz) format to understand the logic.

Programming interface
---------------------

The programming interface will get an in-depth description later. For now, you are advised to look at the source code of [ABC metadata](https://github.com/whitequark/furnace-avm2/tree/master/lib/furnace-avm2/abc/metadata) parser/storage code and [Furnace](https://github.com/whitequark/furnace/tree/master/lib/furnace) source code. Neither of these are particularly large, and you will probably need to read it anyway.

You can also use [Pry](http://pry.github.com/) to explore the interfaces. Try launching the utility `furnace-avm2-shell`.

Contact
-------

If you experience any difficultes, you can ask me (*whitequark*) on channel `#ruby-lang` at `irc.freenode.net` or drop me a email.

License
-------

Furnace-AVM2 is distributed under the terms of MIT license.

    Copyright (c) 2012  Peter Zotov <whitequark@whitequark.org>

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# bash-completion script for mulle-test

# Function to complete mulle-test commands and options
_mulle_test_complete() {
    local cur prev words cword
    _get_comp_words_by_ref -n : cur prev words cword

    local -a global_options=(
        "-h" "--help"
        "-f" "--force"
        "-d" "--dir-name"
        "--configuration"
        "--debug" "--release"
        "--clean-all" "--no-clean" "--clean-option"
        "--no-craft"
        "--valgrind" "--valgrind-no-leaks" "--coverage"
        "--objc-coverage" "--gdb"
        "--sanitize-address" "--sanitize-thread" "--sanitize-undefined"
        "--testallocator" "--zombie"
        "--add-sanitizer" "--add-memory-checker"
        "--no-sanitizer" "--no-sanitizers" "--no-memory-checker" "--no-memory-checkers"
        "--sanitizer"
        "--no-mulle-test-define"
        "--version"
    )

    local commands=(
        "arch" "build" "clean" "cleanrun" "coverage" "craft" "craftorder" "crun" "crerun"
        "env" "fetch" "init" "libexec-dir" "linkorder" "log" "nrerun" "nrun" "propose"
        "rebuild" "recrun" "recraft" "rerun" "retest" "run" "test-dir" "uname" "version"
    )

    local i
    local sanitizers clean_commands clean_options coverage_tools craft_options env_options fetch_options init_options linkorder_options run_options test_dir_options
    for ((i = 1; i < cword; ++i)); do
        if [[ "${words[i]}" == -* ]]; then
            continue
        fi

        case "${words[i]}" in
            -d|--dir-name|--configuration|--clean-option|--add-sanitizer|--add-memory-checker|--sanitizer)
                if [[ $i -eq $cword || $i -eq $((cword - 1)) ]]; then
                    if [[ "$prev" == "-d" || "$prev" == "--dir-name" || "$prev" == "--configuration" || "$prev" == "--clean-option" ]]; then
                        COMPREPLY=()
                        return 0
                    fi
                    if [[ "$prev" == "--add-sanitizer" || "$prev" == "--add-memory-checker" || "$prev" == "--sanitizer" ]]; then
                        sanitizers=("address" "thread" "undefined" "valgrind" "valgrind-no-leaks" "coverage" "objc-coverage" "gdb" "testallocator" "zombie" "gmalloc" "glibc")
                        COMPREPLY=($(compgen -W "${sanitizers[*]}" -- "$cur"))
                        return 0
                    fi
                fi
                ;;
            arch|version|uname|libexec-dir|propose|craftorder|cleanrun|build|rebuild|recraft|retest|recrun|nrun)
                # No further completion after these commands
                COMPREPLY=()
                return 0
                ;;
            clean)
                clean_commands=("all" "tidy" "gravetidy")
                clean_options=("-h" "--help" "--no-var" "--no-graveyard" "-g")
                case "$prev" in
                    --no-var|--no-graveyard|-g)
                        COMPREPLY=()
                        return 0
                        ;;
                    -h|--help)
                        COMPREPLY=()
                        return 0
                        ;;
                    clean)
                        if [[ $cword -eq $((i+1)) ]]; then
                            COMPREPLY=($(compgen -W "${clean_commands[*]}" -- "$cur"))
                            return 0
                        fi
                        COMPREPLY=($(compgen -W "${clean_options[*]}" -- "$cur"))
                        return 0
                        ;;
                    *)
                        COMPREPLY=($(compgen -W "${clean_options[*]} ${clean_commands[*]}" -- "$cur"))
                        return 0
                        ;;
                esac
                ;;
            coverage)
                coverage_tools=("gcovr" "gcov")
                case "$prev" in
                    -h|--help)
                        COMPREPLY=()
                        return 0
                        ;;
                    coverage)
                        COMPREPLY=($(compgen -W "${coverage_tools[*]}" -- "$cur"))
                        return 0
                        ;;
                    *)
                        COMPREPLY=()
                        return 0
                        ;;
                esac
                ;;
            craft)
                craft_options=("-h" "--help" "--build-args" "--run-args" "--coverage" "--debug" "--postprocess" "--no-postprocess" "--release" "--standalone")
                case "$prev" in
                    -h|--help|--coverage|--debug|--postprocess|--no-postprocess|--release|--standalone)
                        COMPREPLY=()
                        return 0
                        ;;
                    --build-args|--run-args)
                        COMPREPLY=()
                        return 0
                        ;;
                    craft)
                        COMPREPLY=($(compgen -W "${craft_options[*]}" -- "$cur"))
                        return 0
                        ;;
                    *)
                        COMPREPLY=($(compgen -W "${craft_options[*]}" -- "$cur"))
                        return 0
                        ;;
                esac
                ;;
            env)
                env_options=("-h" "--help")
                COMPREPLY=($(compgen -W "${env_options[*]}" -- "$cur"))
                return 0
                ;;
            fetch)
                fetch_options=("-h" "--help")
                COMPREPLY=($(compgen -W "${fetch_options[*]}" -- "$cur"))
                return 0
                ;;
            init)
                init_options=("-h" "--help" "--project-name" "--project-language" "--project-dialect" "--project-extensions" "--project-type" "--executable" "--github-name" "--shared" "--standalone")
                case "$prev" in
                    -h|--help|--executable|--shared|--standalone)
                        COMPREPLY=()
                        return 0
                        ;;
                    --project-name|--project-language|--project-dialect|--project-extensions|--project-type|--github-name)
                        COMPREPLY=()
                        return 0
                        ;;
                    init)
                        COMPREPLY=($(compgen -W "${init_options[*]}" -- "$cur"))
                        return 0
                        ;;
                    *)
                        COMPREPLY=($(compgen -W "${init_options[*]}" -- "$cur"))
                        return 0
                        ;;
                esac
                ;;
            libexec-dir)
                # No options
                COMPREPLY=()
                return 0
                ;;
            linkorder)
                linkorder_options=("-h" "--help" "--startup" "--no-startup" "--cached" "--uncached")
                case "$prev" in
                    -h|--help|--startup|--no-startup|--cached|--uncached)
                        COMPREPLY=()
                        return 0
                        ;;
                    linkorder)
                        COMPREPLY=($(compgen -W "list clean ${linkorder_options[*]}" -- "$cur"))
                        return 0
                        ;;
                    *)
                        COMPREPLY=($(compgen -W "list clean ${linkorder_options[*]}" -- "$cur"))
                        return 0
                        ;;
                esac
                ;;
            log)
                # Pass through
                COMPREPLY=()
                return 0
                ;;
            run|crun)
                run_options=("-h" "--help" "-l" "--lenient" "-j" "--jobs" "-V" "--assembler" "--ir" "--no-run-test" "--no-run-script" "--disable-coredumps" "--project-language" "--project-dialect" "--project-extensions" "--path-prefix" "--parallel" "--extensions" "--release" "--debug" "--build-args" "--run-args" "--reuse-exe" "--golden-stdout" "--keep-exe" "--print-exe")
                case "$prev" in
                    -h|--help|-l|--lenient|-V|--assembler|--ir|--no-run-test|--no-run-script|--disable-coredumps|--parallel|--release|--debug|--reuse-exe|--golden-stdout|--keep-exe|--print-exe)
                        COMPREPLY=()
                        return 0
                        ;;
                    -j|--jobs|--project-language|--project-dialect|--project-extensions|--path-prefix|--extensions|--build-args|--run-args)
                        COMPREPLY=()
                        return 0
                        ;;
                    *)
                        if [[ $i -eq $cword ]]; then
                            COMPREPLY=($(compgen -f -- "$cur"))
                            return 0
                        fi
                        COMPREPLY=($(compgen -W "${run_options[*]}" -- "$cur"))
                        return 0
                        ;;
                esac
                ;;
            rerun|nrerun|crerun)
                # Same as run but with limited options
                COMPREPLY=($(compgen -W "-h --help -l --lenient" -- "$cur"))
                return 0
                ;;
            test-dir)
                test_dir_options=("-h" "--help")
                case "$prev" in
                    -h|--help)
                        COMPREPLY=()
                        return 0
                        ;;
                    test-dir)
                        COMPREPLY=()
                        return 0
                        ;;
                    *)
                        COMPREPLY=($(compgen -W "${test_dir_options[*]}" -- "$cur"))
                        return 0
                        ;;
                esac
                ;;
        esac
        return 0
    done

    # Default completions
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "${global_options[*]}" -- "$cur"))
    else
        COMPREPLY=($(compgen -W "${commands[*]}" -- "$cur"))
    fi
}

complete -F _mulle_test_complete mulle-test

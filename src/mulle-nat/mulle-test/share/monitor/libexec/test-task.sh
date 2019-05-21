test_task_run()
{
   log_entry "test_task_run" "$@"

   mulle-test craft &&
   mulle-test run
}

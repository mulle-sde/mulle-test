test_task_run()
{
   log_entry "test_task_run" "$@"

   mulle-test build &&
   mulle-test run
}

## The end?

In this tutorial we've taken a walk through a simple integration of ROM concepts
into a very basic Rails application.

We [got up and running](/tutorials/rails/getting-started) quickly with an
application template and a brief disucussion of the `rom-rails` integration.

Next we [displayed a list of tasks](/tutorials/rails/tasks-index) on the index
page of our new application. This showed us the basics of a ROM
[relation](/introduction/relations).

A simple list of tasks wasn't enough so we explored [extending the tasks
relation](/tutorials/rails/task-relation) to give us a sorted list of tasks
and use it in our views.

Still not satisified we realized that our array of hashes returned from
relations didn't cut it. We [set up a task mapper](/tutorials/rails/task-mapper)
and a `Task` object to give us richer domain objects in our application.

All of that would be greate if we needed a read-only application. [Managing
tasks](/tutorials/rails/managing-tasks) was next for us and there we learned
about ROM [commands](/introduction/commands) and ROM command/query separation.

Taking the command/query separation a little further helped us understand the
ROM way of handling [validations and errors](/tutorials/rails/validations).

What might we like to do next?

* Validate on `update` as well as `create`. Can you think of what you'd need
  to add and/or change to make that work?
* Add task deletion as we mentioned in
  [managing tasks](/tutorials/rails/managing-tasks)
* Add attributes to our `Task` model, perhaps a long description? You should
  be thinking about the database, the model, and relations now.
* What else could we do?

We hope that what we've presented here helps you to better understand how ROM
can be used **today** in your Rails applications and beyond. As always, you can
[fork the website](https://github.com/rom-rb/rom-rb.org/fork), and help others
by making this tutorial better.

Happy ROMing!

# Phoenix Docker Setup

You're here because you want to set up a project that uses Phoenix and runs in Docker, and you wanted a step-by-step
guide (or maybe you're here because you're me and you keep making the same mistakes, so you wanted to write down
exactly how you did it so that you can stop making the same mistakes. Hi future me! I hope things are going well).

A lot of this is based heavily on the [Phoenix Installation Guide](https://hexdocs.pm/phoenix/installation.html),
but because we're Docker-izing this, we'll have to do a few things in a different order.

I'm assuming that you:

 - Have `docker` and `docker-compose` installed, and are at least moderately familiar with them.
 - Want all the normal Phoenix bells and whistles, like its asset management.
 - Don't want to install Elixir on your machine, and would prefer to have all the Elixir stuff happen
   in docker.

## Create the codebase

To begin, we'll need these four files: `docker-compose-setup.yml`, `docker-compose.yml`, `Dockerfile`, and
`.gitignore`. Either copy them from this repo to your project folder or clone this repo as your project folder.

You can easily copy them to your project folder by running this:

```
curl https://raw.githubusercontent.com/joshlarson/phoenix-docker-setup/main/docker-compose-setup.yml > docker-compose-setup.yml
curl https://raw.githubusercontent.com/joshlarson/phoenix-docker-setup/main/docker-compose.yml > docker-compose.yml
curl https://raw.githubusercontent.com/joshlarson/phoenix-docker-setup/main/Dockerfile > Dockerfile
curl https://raw.githubusercontent.com/joshlarson/phoenix-docker-setup/main/.gitignore > .gitignore
```

To create our project, we'll need a temporary Elixir container. Create that and shell into it with this command:

```
docker-compose -f docker-compose-setup.yml run --rm setup bash
```

In that container, run


```
mix archive.install hex phx_new
```

And say yes to the prompts. Now run

```
mix phx.new <project_name>
```

With whatever project name you choose. When it prompts you to fetch and install dependencies, say
"yes" (we don't need the dependencies right now, but we will need `mix.lock`).

Exit out of this shell and you should now be back on your host machine. You should see a folder called
`<project_name>` (you know, whatever you named your project). Look it over to make sure it looks good.

If you did this on Linux, it's possible that those files will wind up being owned by `root` instead
of your user. You can fix that by running

```
sudo chown -R <username>:<groupname> <project_name>
```

(`<group_name>` is usually the same as `<user_name>`, which you can find by running `whoami`.)

Congrats! You've generated your project from within a docker container! Now we just need to set up
the docker containers to run it.

## Make the codebase run in docker

You'll need to make the following changes:

 - Remove `docker-compose-setup.yml`. You don't need it anymore.
 - Open `docker-compose.yml` and replace the two instances of `<project_name>` with your actual project name.
 - Move `Dockerfile` into the `<project_name>` directory.
 - Remove the following folders:
   - `<project_name>/deps`
   - `<project_name>/_build`
 - In `<project_name>/config/`, open up `dev.exs` and `test.exs`. In both files, change the `hostname`
   field in the database section (near the top) to `"db"` instead of `"localhost"`. In `dev.exs`, also
   find the `http` config, and change `{127, 0, 0, 1}` to `{0, 0, 0, 0}`.

That's the code changes you need to make. Now build the images with

```
docker-compose build
```

Create the database by running

```
docker-compose run --rm web mix ecto.create
```

And then start the app with

```
docker-compose up --build
```

(You don't _need_ the `--build` flag for this part, but I prefer to be in the habit of _always_
running `docker-compose up` with that flag in order to make sure that the image I'm using is
always up-to-date.)

The app should then be available at http://localhost:4000/, with nice CSS and Javascript and all.

## If dependencies change

If you update something in `mix.exs`, you'll need to make sure that you get an updated copy of both
`mix.lock` and the installed dependencies that go into the image.

To get an updated `mix.lock`, you need to run `mix deps.get && mix deps.compile` inside the `web`
container. Chances are, you'll do that while you're experimenting with your new dependency anyway,
but in case you wind up with an updated `mix.exs` and no updated `mix.lock`, run

```
docker-compose run --rm web mix deps.get
```

Then, you'll need to rebuild your image before the next time you create a new container. You can do
that with

```
docker-compose build
```

Or if you're in the habit of using the `--build` flag with `docker-compose up`, then

```
docker-compose up --build
```

Will take care of rebuilding for you.

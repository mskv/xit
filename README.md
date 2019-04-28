# Xit

Learning Elixir by implementing a small subset of Git functionality. Pronounced "exit".

### Functionality by example

- build the script

```
❯ mix escript.build
Generated escript xit with MIX_ENV=dev
```

- make a temporary test directory

```
❯ mkdir _tmp && cd _tmp 
```

- initialize the Xit repo

```
❯ ../xit init
  Xit repository initialized.
```

- add some content

```
❯ echo "v1" > root_file

❯ mkdir directory && echo "v1" > directory/nested_file
```

- add the contents of the working directory to the staging area

```
❯ ../xit add .
  Changes indexed.
```

- commit the changes

```
❯ ../xit commit
  Staging area committed.
```

- make some changes: remove one file and change content of another

```
❯ rm root_file

❯ echo "v2" > directory/nested_file
```

- add the changes again

```
❯ ../xit add .
  Changes indexed.
```

- create a second commit

```
❯ ../xit commit
  Staging area committed.
```

- log the history (newest on top)

```
❯ ../xit log
67E7B92EC23BA319EF07BB4F0399AA61B173FC3E
6DE5486A5E266066C3EDED19DD0081BAD603FC61
```

- checkout an older commit

```
❯ ../xit checkout 6DE5486A5E266066C3EDED19DD0081BAD603FC61
Checkout out 6DE5486A5E266066C3EDED19DD0081BAD603FC61
```

- observe the contents of the working directory brought to the correct state

```
❯ cat root_file
v1

❯ cat directory/nested_file
v1
```

- checkout the newer commit

```
❯ ../xit checkout 67E7B92EC23BA319EF07BB4F0399AA61B173FC3E
Checkout out 67E7B92EC23BA319EF07BB4F0399AA61B173FC3E
```

- observe the contents of the working directory brought to the correct state

```
❯ cat root_file
cat: root_file: No such file or directory

❯ cat directory/nested_file
v2
```

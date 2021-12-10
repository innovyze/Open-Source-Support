# Running an Exchange script from the UI
This example shows how to run a Ruby script from the ICM UI which triggers an Exchange script.

Load the `UI_script.rb` script in ICM. This runs the `EX_script.rb` script in Exchange. It also passes arguments from the UI to the Exchange script.

![](gif001.gif)

## Technical note
The `UI_script.rb` script uses the `system()` method, which can pass command line strings to the shell. The command passed to the `system()` method must be surrounded by double-quotes. For example:

In Ruby:
```ruby
system("echo hello world")
```
Is equivalent to running the following command in shell:
```bat
echo hello world
```
Which outputs:
```
hello world
```

In this example, the `system()` method will run the `iexplore.exe` process. In turn, this process needs arguments, such as:
- which Exchange script it is supposed to run (`EX_script.rb` in this example)
- in what product should it run the script (ICM/IAM)
- any arguments the user might want to pass to the Exchange script

Arguments for the `iexplore.exe` process must also be surrounded by double-quotes in case they have spaces. Otherwise, they would be interpreted by as separate individual arguments. This means the double-quotes used for the `iexplore.exe` arguments need to be escaped so the `system()` method does not confuse them with its own double-quotes.

Escaping double-quotes is done by using `\"`. These can then be used to surround the `iexplore.exe` arguments which might contain spaces, and avoid shell interpreting them as separate arguments.

In this line:
```ruby
system("\"#{$exchange_path}\" \"#{$script_path}\" ICM \"#{$arg1}\" \"#{$arg2}\"")
```
The system method has five arguments which be interpreted as:
````
1. "C:/where iexchange.exe is/"
2. "E:/where the script it will run is/"
3. ICM (or IAM)
4. "argument number one"
5. "argument number two"
````
Please check the Ruby documentation for more information about the [`system()`](https://apidock.com/ruby/Kernel/system) method.

The example has a number of hard coded variables for simplicity. This includes running on the 64-bit version of ICM and using a `E:/Scripts` folder as the location of the `EX_script.rb` script.
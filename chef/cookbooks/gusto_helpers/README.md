# gusto_helpers Cookbook

## Usage

This cookbook contains standalone resources, recipes, and libraries particular to Gusto, including Gusto's node methods and other core libraries - `node.gustie` is defined in `libraries/gustie.rb`

## Resources

### partial_file

_n.b. Please use this resource sparingly. In most situations, you can get away with a native `file` resource and the `:create_if_missing` action._

This resource appends content to the end of the file.

Before extending this resource or using it on new files, consider using a `file` resource or the [line cookbook](https://github.com/sous-chefs/line) instead.

#### Actions

`:create` (default) - Appends content to a file

`:delete` -  removes all appended content

#### Properties

**managed_content** String

Content to append or remove.

**path** String

If not specified, uses the resource's name.

_Examples_

```ruby
partial_file "/etc/foo" do
  owner "root"
  managed_content "saml_url = https://foo.example.com"
end
```

Strings are appended without modification. Make sure to transform your input to exact content before passing through. A here document is often useful for long string literals:

```ruby
managed_content <<~HERE
  arbitrary file
  content over
  many lines
HERE
```
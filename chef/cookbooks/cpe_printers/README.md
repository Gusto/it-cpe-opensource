cpe_printers Cookbook
==================

Requirements
------------
macOS

Usage
-----
This cookbook provides idempotent management of CUPS printers on macOS via a custom resource: `macos_printer`.

IPP printers are added via Airprint. LPD printers are supported, but will be removed in a future version of macOS.

### Properties

**description** String

A human-readable name like "2nd floor copier."

**location** String

Physical location like building or floor number.

**printer_name** String

If different from resource name. CUPS doesn't support printer names containing SPACE, TAB, "/", or "#". As such, this resource strips those characters and replace spaces with underscores. For example, `Copier #1 (Paris) 2/4` is transformed to `Copier_1_(Paris)_24`.

**shared** [true, false], default: false

Whether or not the printer is shared.

**uri** String

This resource currently only supports URIs starting with `ipp://` and `lpd://`.

### Example usage

IPP printer
```ruby
macos_printer "Macoun (New York)" do
  description "Macoun (New York)"
  location "8th floor, New York"
  uri "ipp://macoun.example.com"
  action :create
end
```

LPD printer (deprecated)
```ruby
macos_printer "Macoun (New York)" do
  description "Macoun (New York)"
  location "8th floor, New York"
  uri "lpd://macoun.example.com"
  action :create
end
```

# vacli

A ruby script to help you find a COVID-19 vaccine.

## Usage

```bash
ruby ./vacli.rb -s <STATE>

# Search Florida
ruby ./vacli.rb -s FL

# Search IL zipcodes
ruby ./vacli.rb -s IL -z 60601,60622,60657

# Search IL for moderna
ruby ./vacli.rb -s IL -m moderna
```

## TODO

- [ ] daemon

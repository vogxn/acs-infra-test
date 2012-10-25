#gateway_fact.rb

Facter.add("gateway_fact") do
  setcode do
    Facter::Util::Resolution.exec('route -n|awk \'/^0.0.0.0/ {print $2}\'')
  end
end


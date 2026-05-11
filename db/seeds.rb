# Deterministic development data. Everything derives from fixed literals and
# a seeded RNG, so two machines seed identical databases — including invoice
# totals, which go through the real pricing path.

rng = Random.new(20250601)

ActiveRecord::Base.transaction do
  [ InvoiceLineItem, InvoiceRecord, JobPart, Appointment, Job, StockAdjustment,
    StockLevel, Part, ApiToken, User, Technician, Customer ].each(&:delete_all)

  admin = User.create!(
    email: "admin@acme-dispatch.example", name: "Alex Winter",
    role: "admin", password: "dispatch-dev-1"
  )
  User.create!(
    email: "dispatch@acme-dispatch.example", name: "Jo Barnes",
    role: "dispatcher", password: "dispatch-dev-1"
  )

  technicians = [
    [ "Dana Reyes", 8000, %w[hvac electrical], "555-882-4413" ],
    [ "Ben Okada", 5000, %w[plumbing], "555-102-9931" ],
    [ "Marta Fossey", 3333, %w[appliance], "555-449-0018" ],
    [ "Sam Ortiz", 6500, %w[hvac], "555-720-5541" ],
    [ "Iris Chao", 7200, %w[electrical low-voltage], "555-380-2216" ],
    [ "Viktor Hale", 5400, %w[plumbing gas], "555-614-7809" ],
    [ "Lena Brandt", 6100, %w[hvac refrigeration], "555-957-3324" ],
    [ "Ray Whitcomb", 4800, %w[general], nil ]
  ].map do |name, rate, tags, phone|
    Technician.create!(name: name, hourly_cost_cents: rate, skill_tags: tags, phone: phone)
  end

  # Ray retired mid-history; his appointments stay on the books.
  technicians.last.update!(is_active: false)

  streets = [ "Alder Ct", "Bay St", "Cedar Loop", "Dockside Ave", "Elm St",
              "Foundry Rd", "Grove Ln", "Harbor Lane", "Iris Way", "Juniper Dr" ]
  customers = [
    "Meridian Property Group", "Harbor Lane Bakery", "Rosa Quinn", "Cliffside Motel",
    "Van Doren Dental", "Pilot Hill Brewing", "Ada & Sons Grocers", "Fern Hollow Clinic",
    "Marchetti Restaurant Group", "Kite Coffee", "Trent Yarrow", "Bellhaven Apartments",
    "Corner Print Shop", "Salt Flats Gym", "June Okafor-Reid", "Windrose Marina",
    "Pemberton School District", "Halcyon Senior Living", "Iron Kettle Diner", "Vera Lindqvist"
  ].map.with_index do |name, index|
    Customer.create!(
      name: name,
      service_address: "#{100 + index * 7} #{streets[index % streets.size]}",
      contact_email: index.even? ? "contact#{index}@#{name.parameterize}.example" : nil,
      phone: index % 3 == 0 ? "555-#{format('%03d', 200 + index)}-#{format('%04d', 1000 + index * 37)}" : nil,
      notes: index % 5 == 0 ? "Gate code #{2200 + index}. Call ahead." : nil
    )
  end

  part_names = [
    [ "IGN-4420", "Hot surface igniter", 780, 1299 ],
    [ "FLT-2001", "20x25x1 pleated filter", 240, 499 ],
    [ "VLV-0087", "Quarter-turn shutoff valve", 610, 950 ],
    [ "CAP-0450", "45uF run capacitor", 520, 899 ],
    [ "THR-9910", "Smart thermostat base", 4100, 6500 ],
    [ "PMP-3300", "Condensate pump", 2350, 3800 ],
    [ "BLW-7040", "Blower wheel", 1900, 3100 ],
    [ "CTR-2244", "24V contactor", 880, 1450 ],
    [ "FUS-0030", "30A cartridge fuse pair", 310, 550 ],
    [ "GSK-1180", "Burner gasket kit", 450, 780 ],
    [ "TRP-1550", "P-trap assembly", 390, 690 ],
    [ "WAX-0021", "Wax ring with flange", 280, 520 ],
    [ "SUP-1266", "Faucet supply line", 340, 610 ],
    [ "HTR-8800", "40gal heating element", 1650, 2700 ],
    [ "ANV-0666", "Anode rod", 1150, 1950 ],
    [ "BRK-2020", "20A breaker", 720, 1200 ],
    [ "GFI-1515", "GFCI outlet", 980, 1600 ],
    [ "LED-4419", "LED driver 40W", 1240, 2050 ],
    [ "SWT-0303", "3-way switch", 410, 750 ],
    [ "DCT-6090", "6in duct collar", 350, 640 ],
    [ "REF-4104", "R-410A recharge kit", 5200, 8400 ],
    [ "MTR-1230", "Condenser fan motor", 6400, 9900 ],
    [ "BLT-0450", "Belt 4L450", 290, 540 ],
    [ "SEN-7012", "Flame sensor", 660, 1100 ],
    [ "DRN-0900", "Drain auger head", 830, 1350 ]
  ]
  parts = part_names.map do |sku, name, cost, price|
    Part.create!(sku: sku, name: name, unit_cost_cents: cost, unit_price_cents: price)
  end
  parts.each_with_index do |part, index|
    part.stock_level.adjust!(6 + (index * 5) % 20)
  end

  job_titles = [
    "Furnace not igniting", "Deck oven runs cold", "Path light flickering",
    "AC blows warm on floor 3", "Leak under prep sink", "Walk-in cooler icing over",
    "Water heater pilot out", "Panel breaker trips nightly", "Thermostat reads wrong room",
    "Bathroom fan seized", "Grease trap backing up", "Rooftop unit rattles",
    "No hot water in unit 4B", "Outlet dead in records room", "Freezer door gasket torn",
    "Radiator valve stuck", "Sump pump cycling", "Kitchen hood lights out",
    "Boiler pressure dropping", "Ice maker line frozen"
  ]

  # Six statuses, forty jobs. Appointment slots advance per technician so
  # nothing conflicts; a few land on weekends on purpose.
  statuses = %w[requested] * 8 + %w[scheduled] * 8 + %w[in_progress] * 6 +
    %w[completed] * 6 + %w[invoiced] * 7 + %w[cancelled] * 5
  base_day = Date.new(2026, 3, 2) # a Monday
  tech_cursor = Hash.new(0)

  invoiced_totals = []
  statuses.each_with_index do |target, index|
    job = Job.create!(
      customer: customers[index % customers.size],
      title: "#{job_titles[index % job_titles.size]}#{index >= 20 ? " (return visit)" : ""}",
      description: index % 4 == 0 ? "Reported by tenant. See notes on file." : nil,
      priority: %w[low normal normal normal urgent][rng.rand(5)]
    )

    next if target == "requested"

    if target == "cancelled" && index.odd?
      job.transition_to!("cancelled")
      next
    end

    technician = technicians[index % (technicians.size - 1)] # skip retired Ray
    slot = tech_cursor[technician.id]
    tech_cursor[technician.id] += 1
    # Spread bookings across days; every sixth booking lands on a Saturday.
    day = base_day + (slot % 5) + (slot % 6 == 5 ? (6 - (base_day + slot % 5).wday) % 7 : 0)
    start_hour = 8 + (slot * 3) % 9
    duration_minutes = [ 60, 90, 120, 150 ][rng.rand(4)]
    appointment = job.appointments.create!(
      technician: technician,
      scheduled_start: Time.utc(day.year, day.month, day.day, start_hour),
      scheduled_end: Time.utc(day.year, day.month, day.day, start_hour) + duration_minutes * 60
    )

    job.transition_to!("scheduled")
    next if target == "scheduled"

    if target == "cancelled"
      job.transition_to!("cancelled")
      next
    end

    job.transition_to!("in_progress")
    next if target == "in_progress"

    appointment.update!(completion_notes: "Done on site; parts as recorded.")
    rng.rand(3).times do |n|
      part = parts[(index * 3 + n * 7) % parts.size]
      quantity = 1 + rng.rand(3)
      next if part.stock_level.reload.quantity_on_hand < quantity

      JobPart.create!(job: job, part: part, quantity: quantity)
    end
    job.transition_to!("completed")
    next if target == "completed"

    invoiced_totals << job.invoice!.total_cents
  end

  ApiToken.create!(user: admin, name: "seeded example").tap do |token|
    puts "API token for #{admin.email} (shown once): #{token.plaintext}"
  end

  puts "Seeded #{Customer.count} customers, #{Technician.count} technicians, " \
       "#{Job.count} jobs, #{Part.count} parts, #{InvoiceRecord.count} invoice records."
  puts "Invoice totals (cents): #{invoiced_totals.join(', ')}"
  puts "Sign in as admin@acme-dispatch.example / dispatch-dev-1"
end

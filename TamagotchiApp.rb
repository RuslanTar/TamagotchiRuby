module Output
  def output(messages)
    puts messages
  end

  def to_percents(value, max_value)
    value.to_f / max_value * 100
  end

  def clear_console
    print "\e[2J\e[f"
  end
end

class Tamagotchi
  attr_reader :health, :satiety, :mood, :alive, :name, :killed_orks, :ruby_lvl, :ruby_xp, :ruby_max_xp, :alive_time, :efficiency, :death_message
  attr_accessor :warning_value, :max_value, :hunger_resistance, :damage_resistance, :mood_resistance

  include Output

  def initialize (name = "Tamagotchi", max_value = 100, warning_percent = 0.3, hunger_resistance = false, damage_resistance = false, mood_resistance = false)
    @name = name
    max_value = 100 if max_value.to_i < 100
    warning_percent = 0.3 if warning_percent.to_f > 1 || warning_percent.to_f == 0.0
    @max_value, @health, @satiety, @mood = [max_value]*4
    @warning_value = (max_value * warning_percent).to_i
    @random_events = {"walk" => ["stumble", "rock concert", "pool party"], "eat" => ["restaurant"]}
    @alive = true
    @previous_values = {health: @health, satiety: @satiety, mood: @mood}
    @killed_orks = 0
    @ruby_levels = {"Trainee" => 1000, "Junior" => 2000, "Middle" => 3500, "Senior" => 5000}
    @ruby_current_lvl = "Trainee"
    @ruby_xp = 0
    @ruby_max_xp = false
    @alive_time, @last_time_eated, @last_time_slept, @last_time_walked, @last_time_ruby_learned, @last_time_killed_ork = [0]*6
    @efficiency = 1
    @eat_debuff, @sleep_debuff, @walk_debuff = [false]*3
    @hunger_resistance, @damage_resistance, @mood_resistance = hunger_resistance, damage_resistance, mood_resistance
    @death_message = ''
  end

  def eat
    messages = []
    eat_time = rand(1...2)
    event_message = random_event("eat", 0.2)

    if event_message
      eat_time += 2
      messages << event_message
    end

    change_satiety(@max_value * 0.2 * eat_time * @efficiency)
    change_mood(@max_value * 0.05 * eat_time * @efficiency)
    change_health(@max_value * 0.1 * eat_time * @efficiency)
    @alive_time += eat_time
    @last_time_eated = @alive_time
    messages << "[Info] You have ate for #{eat_time} hours."
    messages << all_checks

    alive? ? messages : @death_message
  end

  def walk
    walk_time = rand(1...5)
    messages = []
    event_message = random_event("walk", 0.2)

    if event_message
      walk_time += 2
      messages << event_message
    end

    change_satiety(-@max_value * 0.1 * walk_time)
    change_mood(rand(1..@max_value * 0.2) - @max_value * 0.1)
    @alive_time += walk_time
    @last_time_walked = @alive_time
    messages << "[Info] You have walked for #{walk_time} hour#{'s' unless walk_time == 1}"
    messages << all_checks

    alive? ? messages : @death_message
  end

  def learn_ruby
    learning_time = rand(3..8)
    messages = []

    if @ruby_max_xp
      messages << "[Info] Congrats! You know everything and you dont need to learn Ruby anymore."
    else
      change_satiety(-@max_value * 0.05 * learning_time)
      change_mood(rand(1..@max_value * 0.2) - @max_value * 0.1)
      messages << change_ruby_xp(rand(10..50) * learning_time * @efficiency)
      @alive_time += learning_time
      @last_time_ruby_learned = @alive_time
      messages << "[Info] You have learned Ruby for #{learning_time} hours."
    end
    messages << all_checks

    alive? ? messages : @death_message
  end

  def sleep
    sleep_time = rand(6...9)
    messages = []
    change_health(@max_value * 0.05 * sleep_time)
    change_satiety(-@max_value * 0.05 * sleep_time)
    change_mood(rand(1..@max_value * 0.3) - @max_value * 0.15)
    @alive_time += sleep_time
    @last_time_slept = @alive_time
    messages << "[Info] You have slept for #{sleep_time} hours."
    messages << all_checks

    alive? ? messages : @death_message
  end

  def kill_ork
    kill_time = rand(1...3)
    messages = []

    original_damage = rand(1..100) < 30 ? rand(1..@max_value / 2) : 0
    change_health(-original_damage)
    real_damage = @health - @previous_values[:health]
    change_satiety(-@max_value * 0.05 * kill_time)
    change_mood(@max_value * 0.1 * kill_time)
    @killed_orks += 1
    @alive_time += 1
    @last_time_killed_ork = @alive_time
    messages << (alive? ? "[Info] You killed an Ork and took #{original_damage}#{" (#{'%.1f' % real_damage.abs})" if @damage_resistance} damage. You spend #{kill_time} hour#{'s' unless kill_time == 1} on this." : "[Death] You died in battle with Ork.") + " In total you killed #{@killed_orks} ork#{'s' unless @killed_orks == 1}"
    messages << all_checks

    event_message = random_event("walk",0.3)

    if event_message
      messages << event_message
      @alive_time += 2
    end

    alive? ? messages : @death_message
  end

  def stats
    str_length = @max_value.to_s.length

    health_difference = @health-@previous_values[:health]
    satiety_difference = @satiety-@previous_values[:satiety]
    mood_difference = @mood-@previous_values[:mood]

    message = %(Statistics of #{@name}#{' (Dead)' unless @alive}:
  Health:  #{('%.1f' % @health).to_s.ljust(str_length)} (#{'%.0f' % (to_percents(@health, @max_value))}%#{'⚠' if @health <= @warning_value}) / #{'%+.1f' % health_difference} (#{'%+d' % to_percents(health_difference, @max_value)}%) #{"✓ Resistance" if @damage_resistance}
  Satiety: #{('%.1f' % @satiety).to_s.ljust(str_length)} (#{'%.0f' % (to_percents@satiety, @max_value)}%#{'⚠' if @satiety <= @warning_value}) / #{'%+.1f' % satiety_difference} (#{'%+d' % to_percents(satiety_difference, @max_value)}%) #{"✓ Resistance" if @hunger_resistance}
  Mood:    #{('%.1f' % @mood).ljust(str_length)} (#{'%.0f' % (to_percents(@mood, @max_value))}%#{'⚠' if @mood <= @warning_value}) / #{'%+.1f' % mood_difference} (#{'%+d' % to_percents(mood_difference, @max_value)}%) #{"✓ Resistance" if @mood_resistance}
  Efficiency: #{(@efficiency*100).round}%

#{alive_time})

    @previous_values = {health: @health, satiety: @satiety, mood: @mood}

    message
  end

  def random_event(event_type, probability)
    is_event = rand(0..100) <= probability * 100
    events = @random_events[event_type]

    if is_event
      str = "[Event] !RANDOM EVENT! Your #{@name} "

      str += case events.sample
             when "stumble"
               original_damage = rand(1..@max_value / 3)
               change_health(-original_damage)
               real_damage = @health - @previous_values[:health]
               "has stumbled and took #{original_damage}#{" (#{'%.1f' % real_damage.abs})" if @damage_resistance} damage"
             when "rock concert"
               change_satiety(-10)
               change_mood(10)
               "runs out of the house and goes to a rock concert and then cries on stage."
             when "pool party"
               change_satiety(20)
               change_mood(10)
               "goes to a pool party"
             when "restaurant"
               'goes to a restaurant'
             else
               "Unknown event"
             end
      str
    end
  end

  def alive?
    @alive
  end

  def name=(value)
    old_name = @name
    @name = value
    output "[Info] Tamagotchi's name was changed from \"#{old_name}\" to \"#{@name}\""
  end

  def alive_time
    days = @alive_time / 24
    hours = @alive_time - days * 24
    "Your #{@name} alive already for #{days} day#{'s' unless days == 1} #{hours} hour#{'s' unless hours == 1}"
  end

  private

  attr_accessor :random_events, :previous_values, :last_time_eated, :last_time_slept, :last_time_walked, :last_time_ruby_learned, :last_time_killed_ork, :eat_debuff, :sleep_debuff, :walk_debuff

  def death(reason = "no reason")
    @alive = false
    @death_message = "[Death] Your #{@name} was dead because of #{reason}."
  end

  def all_checks
    messages = []

    checks = [eat_check, sleep_check, walk_check, ruby_learn_check, ork_check]
    checks.map { |e| messages << "[Reminder] #{e}" if e }
    calc_efficiency

    messages
  end

  def eat_check
    starvation_time = @alive_time - @last_time_eated
    satiety_percent = @satiety.to_f / @max_value

    if  satiety_percent <= 0.5
      if starvation_time >= 144# 6 days
        death("starvation")
      elsif starvation_time >= 72 # 3 days
        @eat_debuff = true
        "#{@name} didn't eat for #{starvation_time/24} days. You must eat something so you don't die"
      elsif starvation_time >= 24
        "#{@name} didn't eat for #{starvation_time} hours."
      elsif starvation_time >= 6 # 6 hours
        @eat_debuff = false
        "#{@name} is hungry."
      else
        @eat_debuff = false
      end
    end
  end

  def sleep_check
    no_sleep_time = @alive_time - @last_time_slept

    if no_sleep_time >= 168 # 7 days
      death("lack of sleep")
    elsif no_sleep_time >= 72 # 3 days
      @sleep_debuff = true
      "#{@name} didn't sleep for #{no_sleep_time/24} days. Your mental abilities are reduced by Function, Hallucination, and more.\n-- Even simple tasks are difficult to perform. You have memory problems."
    elsif no_sleep_time >= 24 # 1 day
      @sleep_debuff = false
      "#{@name} wants to sleep. Mood becomes more unstable, cognition deteriorates."
    else
      @sleep_debuff = false
    end
  end

  def walk_check
    no_walks_time = @alive_time - @last_time_walked

    if no_walks_time >= 336 # 2 weeks
      death("didn't walk for a #{no_walks_time/24} days")
    elsif no_walks_time >= 120 # 5 days
      @walk_debuff = true
      "#{@name} didn't walk for #{no_walks_time/24} days. The body begins to let you know about the lack of walks"
    else
      @walk_debuff = false
    end
  end

  def ruby_learn_check
    no_ruby_learn_time = @alive_time - @last_time_ruby_learned

    unless @ruby_max_xp
      if no_ruby_learn_time >= 336 # 2 weeks
        @ruby_xp -= @ruby_levels[@ruby_current_lvl]*0.2
        "#{@name} didn't learned Ruby for a #{no_ruby_learn_time/24} days. You start to forgot some things. XP reduced" # todo check to_f
      elsif no_ruby_learn_time >= 120 # 5 days
        "#{@name} didn't learned Ruby for #{no_ruby_learn_time/24} days. You may forgot some stuff."
      end
    end
  end

  def ork_check
    no_ork_killed_time = @alive_time - @last_time_killed_ork

    if no_ork_killed_time >= 168 # 7 days
      "#{@name} didn't killed a singe Ork for a #{no_ork_killed_time/24} days" # todo to_f
    end
  end

  def calc_efficiency
    efficiency = 1
    efficiency -= 0.2 if @eat_debuff
    efficiency -= 0.3 if @sleep_debuff
    efficiency -= 0.2 if @walk_debuff

    @efficiency = efficiency
  end

  def change_ruby_xp(value)
    msgs = []
    threshold = @ruby_levels[@ruby_current_lvl]
    future_value = @ruby_xp + value

    if future_value > threshold
      if @ruby_current_lvl == "Senior"
        @ruby_xp = threshold
        @ruby_max_xp = true
      else
        levels = @ruby_levels.keys
        @ruby_current_lvl = levels[levels.index(@ruby_current_lvl) + 1]
        @ruby_xp = future_value - threshold
        threshold = @ruby_levels[@ruby_current_lvl]
        msgs << "[Info] Congrats! You are promoted to #{@ruby_current_lvl}"
      end
    elsif future_value < 0
      @ruby_xp = 0
      msgs << "[Error] Something went wrong (Negative value of ruby xp)"
    else
      @ruby_xp = future_value
    end

    finished_xp = @ruby_xp.to_f/threshold
    msgs << "[Info] You are on #{'='*(finished_xp*10).round}#{'-'*((1-finished_xp)*10.abs.round)} #{'%.2f' % (finished_xp*100)}% of your level (#{@ruby_current_lvl})"
  end

  def change_health(value)
    damage_resistance = @damage_resistance ? 0.7 : 1
    value *= damage_resistance if value < 0

    future_value = @health + value
    if future_value > @max_value
      @health = @max_value
    elsif future_value <= 0
      @health = 0
      death("low health level")
    else
      @health = future_value
    end
  end

  def change_satiety(value)
    hunger_resistance = @hunger_resistance ? 0.5 : 1
    value *= hunger_resistance if value < 0

    future_value = @satiety + value
    if future_value > @max_value
      @satiety = @max_value
    elsif future_value <= 0
      @satiety = 0
      death("low satiety level")
    else
      @satiety = future_value
    end
  end

  def change_mood(value)
    mood_resistance = @mood_resistance ? 0.6 : 1
    value *= mood_resistance if value < 0


    future_value = @mood + value
    if future_value > @max_value
      @mood = @max_value
    elsif future_value <= 0
      @mood = 0
      death("low mood level")
    else
      @mood = future_value
    end
  end
end

class TamagotchiController

  include Output

  def initialize(name = "Tamagotchi", max_value = 100, warning_percent=0.2)
    @tamagotchi = create_tamagotchi
    @is_continue = true
  end

  def create_tamagotchi
    clear_console
    output "Hello, you can create your own tamagotchi. Let's start!\nType your tamagotchi's properties:\nEnter name: "
    name = gets.chomp

    max_value = 0
    while max_value < 100
      output "Enter max value of properties in range 100+ (health, mood, etc.) (press Enter to take default value): "
      input = gets
      if input == "\n"
        max_value = nil
        break
      end
      max_value = input.chomp.to_i
    end

    warning_percent = 0
    while warning_percent <= 0 || warning_percent >= 1
      output "Enter warning percent in range 0..1 (press Enter to take default value): "
      input = gets
      if input == "\n"
        warning_percent = nil
        break
      end
      warning_percent = input.chomp.to_f
    end

    output "Do you want to add resistances to your #{name}? (y - Yes/ n - No)"
    resistance_exist = false
    while true
      input = gets.chomp
      case input
      when "y"
        resistance_exist = true
        break
      when "n", ""
        break
      else
        "Unknown command"
      end
    end

    hunger_resistance, damage_resistance, mood_resistance = [false] * 3
    if resistance_exist
      output %(Enter with a space resistance numbers you want:
1 - Damage resistance (-30% to any incoming damage)
2 - Hunger resistance (-50% to hunger effects)
3 - Mood resistance (-40% to negative mood effects))
      input = gets.chomp.split(" ").to_a

      damage_resistance = true if input.include?("1")
      hunger_resistance = true if input.include?("2")
      mood_resistance = true if input.include?("3")
      unless hunger_resistance || damage_resistance || mood_resistance
        output "Didn't recognized any suitable input. Default values set."
      end
    end


    Tamagotchi.new(name, max_value, warning_percent, hunger_resistance, damage_resistance, mood_resistance)
  end

  def input
    output "\nControls:\ne - Eat\nw - Walk\nl - Learn Ruby\ns - Sleep\nk - Kill Ork\nst or stats - Statistic\nn - Change name\nq - Quit"

    gets.chomp.downcase
  end

  def display_stats
    output '-'*30
    output @tamagotchi.stats
    output '-'*30
  end

  def on_death
    done = false

    until done
      output "-- Unfortunately, your tamagotchi (#{@tamagotchi.name}) is dead. You can create new one (c) or exit (q). --"
      input = gets.chomp.downcase

      case input
      when "c"
        @tamagotchi = create_tamagotchi
        run
        done = true
      when "q"
        @is_continue = false
        done = true
      else
        output "Unknown command"
      end
    end
  end

  def run
    while @is_continue
      inp = input
      clear_console

      case inp
      when "e"
        output @tamagotchi.eat
      when "w"
        output @tamagotchi.walk
      when "l"
        output @tamagotchi.learn_ruby
      when "s"
        output @tamagotchi.sleep
      when "k"
        output @tamagotchi.kill_ork
      when "st", "stats"
        # display_stats
      when "n"
        output "Enter name: "
        name = gets.chomp
        clear_console
        @tamagotchi.name = name
      when "q"
        @is_continue = false
      else
        output "Unknown command"
        next
      end

      display_stats

      unless @tamagotchi.alive?
        on_death
      end
    end
  end

  private

  attr_accessor :tamagotchi, :is_continue

end


my_tamagotchi = TamagotchiController.new.run
require 'sqlite3'
require 'singleton'
require_relative 'plays'

class PlaywrightDBConnection < SQLite3::Database
  include Singleton

  def initialize
    super('plays.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class Playwright
  attr_accessor :name, :birth_year

  def self.all
    data = PlaywrightDBConnection.instance.execute("SELECT * FROM playwrights")
    data.map { |datum| Playwright.new(datum) }
  end

  def initialize(options)
    @id = options['id']
    @name = options['name']
    @birth_year = options['birth_year']
  end

  def self.find_by_name(name)
    arr_with_hash = PlaywrightDBConnection.instance.execute(<<-SQL, name)
      SELECT
        *
      FROM
        playwrights
      WHERE
        playwrights.name = ?
    SQL
    ans = []
    arr_with_hash.each do |hash|
      ans << Playwright.new(hash)
    end
    ans
  end

  def create
    raise "#{self} already in database" if @id
    PlaywrightDBConnection.instance.execute(<<-SQL, @name, @birth_year)
      INSERT INTO
        playwrights (name, birth_year)
      VALUES
        (?, ?)
    SQL
    @id = PlaywrightDBConnection.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database" unless @id
    PlaywrightDBConnection.instance.execute(<<-SQL, @name, @birth_year, @id)
      UPDATE
        playwrights
      SET
        name = ?, birth_year = ?
      WHERE
        id = ?
    SQL
  end

  def get_plays
    name = self.name
    arr_with_hash = PlaywrightDBConnection.instance.execute(<<-SQL, name)
      SELECT
        *
      FROM
        playwrights
      JOIN
        plays ON playwrights.id = plays.playwright_id
      WHERE
        playwrights.name = ?
    SQL
    ans = []
    arr_with_hash.each do |hash|
      ans << Play.new(hash)
    end
    ans
  end


end

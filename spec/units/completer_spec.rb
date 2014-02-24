require 'spec_helper'
require 'gitsh/completer'

describe Gitsh::Completer do
  it 'completes commands and aliases' do
    readline = stub('Readline', line_buffer: '')
    env = stub(
      'Environment',
      git_commands: %w( stage stash status add commit ),
      git_aliases: %w( adder )
    )
    internal_command = stub('InternalCommand', commands: %w( :set :exit ))
    completer = Gitsh::Completer.new(readline, env, internal_command)

    expect(completer.call('sta')).to eq ['stage ', 'stash ', 'status ']
    expect(completer.call('ad')).to eq ['add ', 'adder ']
  end

  it 'completes internal commands' do
    readline = stub('Readline', line_buffer: '')
    env = stub('Environment', git_commands: %w( stage stash ), git_aliases: [])
    internal_command = stub('InternalCommand', commands: %w( :set :exit ))
    completer = Gitsh::Completer.new(readline, env, internal_command)

    expect(completer.call(':')).to eq [':set ', ':exit ']
    expect(completer.call(':s')).to eq [':set ']
  end

  it 'completes heads when a command has been entered' do
    readline = stub('Readline', line_buffer: 'checkout ')
    env = stub('Environment', repo_heads: %w( master my-feature v1.0 ))
    internal_command = stub('InternalCommand')
    completer = Gitsh::Completer.new(readline, env, internal_command)

    expect(completer.call('')).to include 'master ', 'my-feature ', 'v1.0 '
    expect(completer.call('m')).to include 'master ', 'my-feature '
    expect(completer.call('m')).not_to include 'v1.0 '
  end

  it 'completes paths beginning with a ~ character' do
    readline = stub('Readline', line_buffer: ':cd ')
    env = stub('Environment', repo_heads: %w( master ))
    internal_command = stub('InternalCommand')
    completer = Gitsh::Completer.new(readline, env, internal_command)

    expect(completer.call('~/')).to include "#{first_regular_file('~')} "
  end

  it 'completes paths containing .. and .' do
    project_root = File.expand_path('../../../', __FILE__)
    path = File.join(project_root, 'spec/./units/../units')
    readline = stub('Readline', line_buffer: ':cd ')
    env = stub('Environment', repo_heads: %w( master ))
    internal_command = stub('InternalCommand')
    completer = Gitsh::Completer.new(readline, env, internal_command)

    expect(completer.call("#{path}/")).to include "#{first_regular_file(path)} "
  end

  it 'completes paths containing spaces' do
    in_a_temporary_directory do
      write_file('some text file.txt', "Some text\n")
      readline = stub('Readline', line_buffer: 'add ')
      env = stub('Environment', repo_heads: %w( master ))
      internal_command = stub('InternalCommand')
      completer = Gitsh::Completer.new(readline, env, internal_command)

      expect(completer.call('som')).to include 'some\ text\ file.txt '
    end
  end

  it 'completes heads starting with :' do
    readline = stub('Readline', line_buffer: 'push ')
    env = stub('Environment', repo_heads: %w( master hello-branch ))
    internal_command = stub('InternalCommand')
    completer = Gitsh::Completer.new(readline, env, internal_command)

    expect(completer.call('master:h')).to include 'master:hello-branch '
  end

  it 'ignores input before punctuation when completing heads' do
    readline = stub('Readline', line_buffer: 'push ')
    env = stub('Environment', repo_heads: %w( master ))
    internal_command = stub('InternalCommand')
    completer = Gitsh::Completer.new(readline, env, internal_command)

    expect(completer.call('mas:')).to eq [ 'mas:master ' ]
  end

  def first_regular_file(directory)
    expanded_directory = File.expand_path(directory)
    Dir["#{expanded_directory}/*"].
      find { |path| File.file?(path) }.
      sub(expanded_directory, directory)
  end
end

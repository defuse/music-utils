# Chord Progression Generator (Four Triads)

require 'midilib/sequence'
require 'midilib/consts'

# This sets the scale mode (e.g. major, minor, etc.)
MODE = [2, 1, 2, 2, 1, 2, 2]
# The human name of the scale, for the generated filenames.
MODE_HUMAN_NAME = "minor"
# The MIDI note number at which to begin the scale (default: A4)
KEYNOTE = 57
# Where to generate the MIDI files.
OUTPUT_DIRECTORY = "output/"
# The MIDI velocity.
VELOCITY = 127
# The BPM.
BPM = 120

# Narrow down the list of progressions with filtering logic here.
def chord_progression_filter(progression)
  progression.include? 0
end

def get_scale_note(keynote, mode, scale_offset)
  note = keynote
  position = 0
  while scale_offset > 0
    note += mode[position]
    position = (position + 1) % mode.length
    scale_offset -= 1
  end
  return note
end

unless Dir.exist? OUTPUT_DIRECTORY
  Dir.mkdir(OUTPUT_DIRECTORY)
end

7.times do |triad1|
  7.times do |triad2|
    7.times do |triad3|
      7.times do |triad4|
        # Filter into a more managable set.
        if chord_progression_filter([triad1, triad2, triad3, triad4])
          name = "#{triad1+1}#{triad2+1}#{triad3+1}#{triad4+1}-#{MODE_HUMAN_NAME}"
          print "#{name}...\n"

          seq = MIDI::Sequence.new()

          track = MIDI::Track.new(seq)
          seq.tracks << track
          track.events << MIDI::Tempo.new(MIDI::Tempo.bpm_to_mpq(BPM))
          track.events << MIDI::MetaEvent.new(MIDI::META_SEQ_NAME, name)

          track = MIDI::Track.new(seq)
          seq.tracks << track

          track.name = name
          track.instrument = MIDI::GM_PATCH_NAMES[0]

          track.events << MIDI::Controller.new(0, MIDI::CC_VOLUME, VELOCITY)

          track.events << MIDI::ProgramChange.new(0, 1, 0)
          half_note_len = seq.note_to_delta('half')

          i=0
          [triad1, triad2, triad3, triad4].each do |triad|
            track.events << MIDI::NoteOn.new(0, get_scale_note(KEYNOTE, MODE, triad), VELOCITY, 0)
            track.events << MIDI::NoteOn.new(0, get_scale_note(KEYNOTE, MODE, triad + 2), VELOCITY, 0)
            track.events << MIDI::NoteOn.new(0, get_scale_note(KEYNOTE, MODE, triad + 4), VELOCITY, 0)

            track.events << MIDI::NoteOff.new(0, get_scale_note(KEYNOTE, MODE, triad), VELOCITY, half_note_len)
            track.events << MIDI::NoteOff.new(0, get_scale_note(KEYNOTE, MODE, triad+2), VELOCITY, 0)
            track.events << MIDI::NoteOff.new(0, get_scale_note(KEYNOTE, MODE, triad+4), VELOCITY, 0)

            i += 1
          end

          File.open(File.join(OUTPUT_DIRECTORY, "#{name}.mid"), 'wb') do |file|
            seq.write(file)
          end
        end
      end
    end
  end
end

print "Done!\n"

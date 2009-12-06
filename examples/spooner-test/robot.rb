require 'rubygems'
require 'rave'

module SpoonerTest
  class Robot < Rave::Models::Robot
    
    SPELLY = 'spelly@gwave.com'
    DELETE_COMMAND = 'DELETE'

    # Reply to the blip the event was generated by.
    def reply_blip(event, message)
      blip = event.blip.create_child_blip
      blip.append_text(message)
    end

    # Reply to the wavelet the event was generated by.
    def reply_wavelet(event, message)
      blip = event.blip.wavelet.create_blip
      blip.append_text(message)
    end
    
    def wavelet_self_added(event, context)
      message =<<-MESSAGE
Hello everyone, I am #{id}!
* My project can be found at http://github.com/diminish7/rave
* I like to comment on what people are doing (submitting and deleting blips).
* I will say hello and goodbye as people arrive or leave the wave.
* Submit a blip containing only "#{DELETE_COMMAND}" and I'll delete it for you.
MESSAGE

      reply_wavelet(event, message)
    end

    # BUG: Never received.
    def wavelet_self_removed(event, context)
      reply_wavelet(event, "Goodbye world!")
    end
    
    def wavelet_participants_changed(event, context)
      event.participants_added.each do |participant|
        reply_wavelet(event, "Hello #{participant}!") if participant != id
      end
      
      event.participants_removed.each do |participant|
        reply_wavelet(event, "Goodbye #{participant}!") if participant != id
      end
    end

    # BUG: Only seems to get sent if robot is invited into a new wave on creation.
    def wavelet_blip_created(event, context)
      if event.modified_by != id
        reply_blip(event, "#{event.modified_by} created a blip! I would have done it better, though...")
      end
    end

    # BUG: Never received.
    def wavelet_blip_removed(event, context)
      if event.modified_by != id
        reply_wavelet(event, "#{event.modified_by} removed a blip from the wavelet! Absolute power, eh?")
      end
    end

    def blip_deleted(event, context)
        if event.modified_by != id
          reply_wavelet(event, "#{event.modified_by} deleted a blip! Which one will be next?")
        end
    end

    def blip_submitted(event, context)
        if event.modified_by != id
          if event.blip.content == DELETE_COMMAND
            if event.blip.root?
              reply_blip(event, "Silly #{event.modified_by}! I can't delete the root blip, can I?")
            else
              event.blip.delete
            end
          else
            reply_blip(event, "#{event.modified_by} submitted a blip! Show off!")
          end
        end
    end

    # BUG: Never received.
    def wavelet_title_changed(event, context)
      if event.modified_by != id
        reply_wavelet(event, "#{event.modified_by} changed the title to: #{event.title}")
      end
    end
    
    def document_changed(event, context)
      unless [id, SPELLY].include? event.modified_by
        # Do something about it.
      end
    end
  end
end

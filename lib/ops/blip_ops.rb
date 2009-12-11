#Reopen the blip class and add operation-related methods
module Rave
  module Models
    class Blip

      VALID_FORMATS = [:plain, :html, :textile]
      
      #Clear the content
      def clear
        @context.add_operation(
                                    :type => Operation::DOCUMENT_DELETE, 
                                    :blip_id => @id, 
                                    :wavelet_id => @wavelet_id, 
                                    :wave_id => @wave_id,
                                    :index => 0, 
                                    :property => 0..(@content.length)
                                  )
        @content = ''
      end
      
      #Insert text at an index
      def insert_text(index, text)
        @context.add_operation(
                                    :type => Operation::DOCUMENT_INSERT, 
                                    :blip_id => @id, 
                                    :wavelet_id => @wavelet_id, 
                                    :wave_id => @wave_id,
                                    :index => index, 
                                    :property => text
                                  )
        @content.insert(index, text)
      end
      
      #Set the content text of the blip
      def set_text(text, options = {})
        clear
        append_text(text, options)
      end
      
      #Deletes the text in a given range and replaces it with the given text
      def set_text_in_range(range, text)
        raise ArgumentError.new("Requires a Range, not a #{range.class.name}") unless range.kind_of? Range
        
        #Note: I'm doing this in the opposite order from the python API, because
        # otherwise, if you are setting text at the end of the content, the cursor
        # gets moved to the start of the range...
        begin # Failures in this method should give us a range error.
          insert_text(range.min, text)
        rescue IndexError => e
          raise RangeError.new(e.message)
        end
        delete_range(range.min+text.length..range.max+text.length)
      end
      
      #Appends text to the end of the content
      def append_text(text, options = {})
        format = options[:format] || :plain
        raise BadOptionError.new(:format, VALID_FORMATS, format) unless VALID_FORMATS.include? format
        
        plain_text = text
        
        if format == :textile
          text = RedCloth.new(text).to_html
          format = :html # Can now just treat it as HTML.
        end

        if format == :html
          type = Operation::DOCUMENT_APPEND_MARKUP
          plain_text = strip_html_tags(text)
        else
          type = Operation::DOCUMENT_APPEND
        end
        
        @context.add_operation(
                                    :type => type,
                                    :blip_id => @id, 
                                    :wavelet_id => @wavelet_id, 
                                    :wave_id => @wave_id,
                                    :property => text # Markup sent to Wave.
                                  )
        # TODO: Add annotations for the tags we removed.
        @content += plain_text # Plain text added to text field.
      end
      
      #Deletes text in the given range
      def delete_range(range)
        raise ArgumentError.new("Requires a Range, not a #{range.class.name}") unless range.kind_of? Range
        
        @context.add_operation(
                                    :type => Operation::DOCUMENT_DELETE, 
                                    :blip_id => @id, 
                                    :wavelet_id => @wavelet_id, 
                                    :wave_id => @wave_id,
                                    :index => range.min,
                                    :property => range
                                  )
         @content[range] = ''
      end
      
      #Annotates the entire content
      def annotate_document(name, value)
        raise NotImplementedError
      end
      
      #Deletes the annotation with the given name
      def delete_annotation_by_name(name)
        raise NotImplementedError
      end
      
      #Deletes the annotations with the given key in the given range
      def delete_annotation_in_range(range, name)
        raise NotImplementedError
      end
      
      #Appends an inline blip to this blip
      def append_inline_blip
        raise NotImplementedError
      end
      
      #Deletes an inline blip from this blip
      def delete_inline_blip(blip_id)
        raise NotImplementedError
      end
      
      #Inserts an inline blip at the given position
      def insert_inline_blip(position)
        raise NotImplementedError
      end
      
      #Deletes an element at the given position
      def delete_element(position)
        raise NotImplementedError
      end
      
      #Inserts the given element in the given position
      def insert_element(position, element)
        raise NotImplementedError
      end
      
      #Replaces the element at the given position with the given element
      def replace_element(position, element)
        raise NotImplementedError
      end
      
      #Appends an element
      def append_element(element)
        raise NotImplementedError
      end

    protected
      def strip_html_tags(text) # :nodoc:
        text.gsub(/<\/?[^<]*>/, '')
      end
    end
  end
end

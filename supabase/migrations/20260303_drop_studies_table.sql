DROP TABLE IF EXISTS studies;
CREATE TABLE public.studies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL,
  title text NOT NULL,
  description text NOT NULL,
  status text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT studies_slug_key UNIQUE (slug),
  CONSTRAINT studies_status_check CHECK (status = ANY (ARRAY['recruiting', 'recruiting paused', 'closed']))
);Button("Show Loudness Match Slider (Test)") {
    showLoudnessMatch = true
}
.sheet(isPresented: $showLoudnessMatch) {
    LoudnessMatchView()
}
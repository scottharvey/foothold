module Foothold
  class Sweep
    class PruneRuns < Base
      def call
        SweepRun.where(started_at: ...threshold(:sweep_run_retention_days).days.ago).delete_all
      end
    end
  end
end
